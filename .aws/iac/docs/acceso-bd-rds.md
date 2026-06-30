# Acceso a la base de datos RDS y carga del schema

Guía para conectarse a la instancia **RDS MySQL** del proyecto (`db-stack`, step_03),
cargar el schema/datos y dejar la app operativa. Complementa `despliegue-aws.md`.

---

## 1. Por qué hace falta esto

- La instancia RDS se crea **privada** (`PubliclyAccessible: false`, en subredes sin acceso
  directo desde Internet). Su Security Group solo acepta el puerto **3306** desde el Security
  Group de la aplicación (ECS). Esto es correcto por seguridad.
- CloudFormation crea la instancia y la base `db_hotel`, **pero no ejecuta el SQL** del repo.
  Por eso, recién desplegada, `db_hotel` está **vacía** (sin tablas).
- La app Java conecta bien a RDS (usuario maestro `admin` vía Secrets Manager), pero el
  **login devuelve HTTP 500** porque la consulta `SELECT ... FROM usuarios` falla: la tabla
  no existe hasta cargar el schema.

**Conclusión:** tras un despliegue nuevo de la BD hay que **cargar `database/db_hotel.sql`**
una vez. Este documento explica cómo hacerlo de forma temporal y segura.

---

## 2. Datos de conexión

| Dato | Valor |
|------|-------|
| Endpoint (host) | `reserva-hotel-db-dev-mysql.cnwbizaxdasc.us-east-1.rds.amazonaws.com` |
| Puerto | `3306` |
| Base de datos | `db_hotel` |
| Usuario / clave | gestionados por RDS en **Secrets Manager** (no hardcodear) |
| Región | `us-east-1` |

> El endpoint puede cambiar si se recrea la instancia. Obtén el actual con:
> ```bash
> aws cloudformation describe-stacks --stack-name reserva-hotel-db-dev \
>   --query "Stacks[0].Outputs[?OutputKey=='ExportedDbEndpoint'].OutputValue" --output text
> ```

> **¿No sabes tu usuario y clave del 3306?** No hay que inventarlos: RDS genera el usuario
> maestro y guarda la contraseña en **AWS Secrets Manager**. La forma más rápida de verlos:
>
> ```bash
> scripts/deploy.sh db-creds
> ```
> Imprime **Host, Puerto (3306), Base, Usuario y Password** listos para pegar en tu gestor.

### Obtener usuario y contraseña (Secrets Manager)

> Atajo: `scripts/deploy.sh db-creds` hace exactamente lo de abajo por ti.

El secret es un JSON `{"username":"...","password":"..."}` administrado por RDS:

```bash
# ARN del secret (Output del db-stack)
SECRET_ARN=$(aws cloudformation describe-stacks --stack-name reserva-hotel-db-dev \
  --query "Stacks[0].Outputs[?OutputKey=='ExportedDbSecretArn'].OutputValue" --output text)

# Credenciales
aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" \
  --query SecretString --output text
```

PowerShell:
```powershell
$arn = aws cloudformation describe-stacks --stack-name reserva-hotel-db-dev `
  --query "Stacks[0].Outputs[?OutputKey=='ExportedDbSecretArn'].OutputValue" --output text
$c = (aws secretsmanager get-secret-value --secret-id $arn --query SecretString --output text | ConvertFrom-Json)
$c.username; $c.password
```

---

## 3. Conexión por la URL del endpoint (acceso temporal)

> ⚠️ **La RDS es privada.** Para conectarte desde tu equipo por el endpoint público debes
> habilitar acceso temporal (pasos abajo) y **revertirlo al terminar**. Para producción usa
> las alternativas seguras de la sección 6 (bastion/SSM), no expongas la BD a Internet.

### 3.0 Forma fácil (recomendada): `deploy.sh`

```bash
scripts/deploy.sh db-open     # 1) habilita acceso temporal a RDS desde tu IP
scripts/deploy.sh db-creds    # 2) muestra host/puerto/usuario/clave para tu gestor
# ... conéctate con MySQL Workbench / DBeaver y trabaja ...
scripts/deploy.sh db-close    # 3) cierra el acceso (RDS vuelve a privada)
```

Esto automatiza exactamente los pasos manuales de abajo (3.1–3.3 y 5). Úsalos solo si
quieres entender el detalle o no tienes el script a mano.

### 3.1 Habilitar acceso temporal (2 pasos, manual)

```powershell
# (a) Marcar la instancia como accesible públicamente
aws rds modify-db-instance --db-instance-identifier reserva-hotel-db-dev-mysql `
  --publicly-accessible --apply-immediately

# (b) Abrir 3306 SOLO a tu IP pública actual en el SG de la BD
$myip = (Invoke-RestMethod https://checkip.amazonaws.com).Trim()
aws ec2 authorize-security-group-ingress --group-id sg-0b8e06afb379dee82 `
  --protocol tcp --port 3306 --cidr "$myip/32"
```

Espera ~2-4 min hasta que `PubliclyAccessible=true`, `status=available` y el endpoint
resuelva a una IP pública:
```powershell
aws rds describe-db-instances --db-instance-identifier reserva-hotel-db-dev-mysql `
  --query "DBInstances[0].{Public:PubliclyAccessible,Status:DBInstanceStatus}" --output json
```

> **Si tu IP cambió** (las IP residenciales son dinámicas): repite el paso (b) con tu IP
> nueva, y revoca la regla vieja con `revoke-security-group-ingress` (ver 5).
> El SG de la BD es `sg-0b8e06afb379dee82`.

### 3.2 Conectar con MySQL Workbench / DBeaver

- Hostname: `reserva-hotel-db-dev-mysql.cnwbizaxdasc.us-east-1.rds.amazonaws.com`
- Port: `3306`
- Username / Password: los del secret (sección 2)
- Default schema: `db_hotel`

### 3.3 Conectar con cliente `mysql`

Con mysql instalado:
```bash
mysql -h reserva-hotel-db-dev-mysql.cnwbizaxdasc.us-east-1.rds.amazonaws.com \
      -P 3306 -u admin -p db_hotel
```

Sin mysql local, usando Docker (la clave va por `MYSQL_PWD` para no exponerla en el comando):
```powershell
$ep = "reserva-hotel-db-dev-mysql.cnwbizaxdasc.us-east-1.rds.amazonaws.com"
$arn = aws cloudformation describe-stacks --stack-name reserva-hotel-db-dev `
  --query "Stacks[0].Outputs[?OutputKey=='ExportedDbSecretArn'].OutputValue" --output text
$c = (aws secretsmanager get-secret-value --secret-id $arn --query SecretString --output text | ConvertFrom-Json)
docker run --rm -it -e MYSQL_PWD=$($c.password) mysql:8 `
  mysql --ssl-mode=DISABLED -h $ep -P 3306 -u $($c.username) db_hotel
```

---

## 4. Cargar el schema y los datos

> **Forma fácil:** `scripts/deploy.sh seed` carga `database/db_hotel.sql` + migraciones
> automáticamente (abre acceso temporal a RDS y lo cierra solo). Además, `scripts/deploy.sh up`
> ya ejecuta este paso, por lo que un despliegue nuevo deja el login funcionando sin pasos
> manuales. Lo de abajo es el detalle manual equivalente.

El script `database/db_hotel.sql` empieza con `DROP DATABASE IF EXISTS db_hotel;
CREATE DATABASE db_hotel; USE db_hotel;`, así que **conéctate sin base por defecto** (él la
crea). ⚠️ Esto **borra y recrea** `db_hotel`: solo cárgalo en una BD nueva/vacía.

```powershell
$ep = "reserva-hotel-db-dev-mysql.cnwbizaxdasc.us-east-1.rds.amazonaws.com"
$arn = aws cloudformation describe-stacks --stack-name reserva-hotel-db-dev `
  --query "Stacks[0].Outputs[?OutputKey=='ExportedDbSecretArn'].OutputValue" --output text
$c = (aws secretsmanager get-secret-value --secret-id $arn --query SecretString --output text | ConvertFrom-Json)
$sqlDir = "<ruta-al-repo>\database"

# Schema + datos semilla
docker run --rm -v "${sqlDir}:/sql" -e MYSQL_PWD=$($c.password) mysql:8 `
  sh -c "mysql --ssl-mode=DISABLED -h $ep -P 3306 -u $($c.username) < /sql/db_hotel.sql"

# (Opcional) migraciones adicionales — NO recrean la base, aplican sobre db_hotel:
docker run --rm -v "${sqlDir}:/sql" -e MYSQL_PWD=$($c.password) mysql:8 `
  sh -c "mysql --ssl-mode=DISABLED -h $ep -u $($c.username) db_hotel < /sql/db_hotel_migracion_reservas.sql"
docker run --rm -v "${sqlDir}:/sql" -e MYSQL_PWD=$($c.password) mysql:8 `
  sh -c "mysql --ssl-mode=DISABLED -h $ep -u $($c.username) db_hotel < /sql/db_hotel_migracion_productos_precio.sql"
```

### Verificar la carga
```powershell
docker run --rm -e MYSQL_PWD=$($c.password) mysql:8 sh -c `
 "mysql --ssl-mode=DISABLED -h $ep -u $($c.username) -e 'SELECT id,username,rol,estado FROM db_hotel.usuarios;'"
```
Debe listar 3 usuarios (1 `empleado`, 2 `cliente`).

---

## 5. Revertir a privada (¡importante, al terminar!)

```powershell
# Quitar acceso público
aws rds modify-db-instance --db-instance-identifier reserva-hotel-db-dev-mysql `
  --no-publicly-accessible --apply-immediately

# Revocar la regla 3306 de tu IP. Localiza el ID de la regla:
aws ec2 describe-security-groups --group-ids sg-0b8e06afb379dee82 `
  --query "SecurityGroups[0].IpPermissions[?FromPort==``3306``]" --output json
# y revócala:
aws ec2 revoke-security-group-ingress --group-id sg-0b8e06afb379dee82 `
  --security-group-rule-ids <sgr-id>
```
Confirma `PubliclyAccessible=false` y que el SG vuelva a tener solo la regla 3306 desde el SG
de la app (`sg-00c46168a50d768cd`).

---

## 6. Credenciales de login de la app

Tras cargar el schema, inicia sesión en la app (`http://<ALB-DNS>/login.jsp`) con la cuenta
semilla:

| Campo | Valor |
|-------|-------|
| Usuario | `alex.quispe@gmail.com` |
| Clave | `12345678` |
| Rol | `empleado` |

> Solo el rol **`empleado`** está soportado por `AuthService` (el flujo `cliente` está
> comentado). En el **primer login**, la clave semilla en texto plano se re-guarda como hash
> **bcrypt** automáticamente (`AuthService.rehashearPassword`); es un UPDATE esperado.

---

## 7. Alternativas seguras (recomendadas para producción)

Exponer la RDS a Internet (aunque sea a una sola IP) no es ideal. Opciones sin abrir la BD:

- **Bastion EC2 + túnel SSH:** EC2 t3.micro en subred pública, dentro del SG de la app.
  ```bash
  ssh -i key.pem -L 3306:reserva-hotel-db-dev-mysql.cnwbizaxdasc.us-east-1.rds.amazonaws.com:3306 ec2-user@<bastion-ip>
  # luego conecta tu cliente a localhost:3306
  ```
- **SSM port forwarding:** EC2 con instance profile de SSM (sin llave ni inbound):
  ```bash
  aws ssm start-session --target i-xxxx \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host=<rds-endpoint>,portNumber=3306,localPortNumber=3306
  ```
- **Automatizar el seed:** ya implementado en `scripts/deploy.sh seed` (lo invoca `up`). Para
  producción, una variante más segura sería ejecutar `db_hotel.sql` como tarea one-off de
  ECS/CodeBuild dentro de la VPC (sin exponer la BD a Internet).

---

## Referencia rápida de recursos

| Recurso | Valor |
|---------|-------|
| Instancia RDS | `reserva-hotel-db-dev-mysql` |
| SG de la BD | `sg-0b8e06afb379dee82` |
| SG de la app (origen permitido a 3306) | `sg-00c46168a50d768cd` |
| Secret de credenciales | Output `ExportedDbSecretArn` del `reserva-hotel-db-dev` |
| Script de schema | `database/db_hotel.sql` |
