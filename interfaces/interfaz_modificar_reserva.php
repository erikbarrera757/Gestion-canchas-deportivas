<?php

include("../conexion.php");

$mensaje = "";
$tipo_mensaje = "";

if(isset($_GET["cancelar"]))
{
    $id = $_GET["cancelar"];

    mysqli_query(
        $conexion,
        "DELETE FROM reserva
        WHERE id_reserva='$id'"
    );

    $mensaje = "Reserva cancelada correctamente.";
    $tipo_mensaje = "success";
}

if(isset($_POST["guardar"]))
{
    $idReserva = $_POST["id_reserva"];
    $idCancha = $_POST["cancha"];
    $fecha = $_POST["fecha"];
    $hora = $_POST["hora"];

    $verificar = "
    SELECT *
    FROM reserva
    WHERE id_cancha='$idCancha'
    AND fecha='$fecha'
    AND hora='$hora'
    AND id_reserva<>'$idReserva'
    ";

    $resultado = mysqli_query(
        $conexion,
        $verificar
    );

    if(mysqli_num_rows($resultado) > 0)
    {
        $mensaje = "La cancha ya se encuentra ocupada.";
        $tipo_mensaje = "error";
    }
    else
    {
        mysqli_query(
            $conexion,
            "UPDATE reserva
             SET
             id_cancha='$idCancha',
             fecha='$fecha',
             hora='$hora'
             WHERE id_reserva='$idReserva'"
        );

        $mensaje = "Reserva modificada correctamente.";
        $tipo_mensaje = "success";
    }
}

?>

<!DOCTYPE html>
<html lang="es">

<head>

<meta charset="UTF-8">

<meta name="viewport"
content="width=device-width, initial-scale=1.0">

<title>Modificar Reserva</title>

<link rel="stylesheet"
href="../css/estilos.css">

</head>

<body>

<header>

<h1>
✏️ MODIFICAR RESERVAS
</h1>

<p>
Gestión de Reservas Deportivas
</p>

</header>

<div class="contenedor">

<?php

if($mensaje != "")
{
?>

<script>
    function mostrarNotificacion(mensaje, tipo = 'info', duracion = 5000) {
        const container = document.getElementById('notificationContainer');
        const toast = document.createElement('div');
        toast.className = `toast ${tipo}`;
        
        const iconos = {
            success: '✅',
            error: '❌',
            warning: '⚠️',
            info: 'ℹ️'
        };
        
        toast.innerHTML = `
            <span class="toast-icon">${iconos[tipo]}</span>
            <span class="toast-message">${mensaje}</span>
            <button class="toast-close" onclick="this.parentElement.remove()">✕</button>
        `;
        
        container.appendChild(toast);
        
        setTimeout(() => {
            if (toast.parentElement) {
                toast.classList.add('fade-out');
                setTimeout(() => toast.remove(), 300);
            }
        }, duracion);
    }
    
    window.addEventListener('load', function() {
        mostrarNotificacion('<?php echo addslashes($mensaje); ?>', '<?php echo $tipo_mensaje; ?>');
    });
</script>

<?php
}
?>

<div class="card">

<h2>
📋 Reservas Registradas
</h2>

<table>

<tr>

<th>ID</th>
<th>Cliente</th>
<th>Cancha</th>
<th>Fecha</th>
<th>Hora</th>
<th>Total</th>
<th>Acciones</th>

</tr>

<?php

$sql = "

SELECT

r.id_reserva,
c.nombre,
c.apellido,
ca.nombre AS cancha,
r.fecha,
r.hora,
r.total

FROM reserva r

INNER JOIN cliente c
ON r.id_cliente=c.id_cliente

INNER JOIN cancha ca
ON r.id_cancha=ca.id_cancha

ORDER BY r.fecha

";

$reservas = mysqli_query(
$conexion,
$sql
);

while($fila=mysqli_fetch_assoc($reservas))
{
?>

<tr>

<td>

<?php echo $fila["id_reserva"]; ?>

</td>

<td>

<?php

echo $fila["nombre"]
." ".
$fila["apellido"];

?>

</td>

<td>

<?php echo $fila["cancha"]; ?>

</td>

<td>

<?php echo $fila["fecha"]; ?>

</td>

<td>

<?php echo $fila["hora"]; ?>

</td>

<td>

Bs.
<?php echo $fila["total"]; ?>

</td>

<td>

<a
class="btn"
href="?editar=<?php
echo $fila['id_reserva'];
?>">
Modificar
</a>

<a
class="btn btn-danger"
href="?cancelar=<?php
echo $fila['id_reserva'];
?>"
onclick="return confirm('¿Desea cancelar la reserva?')">

Cancelar

</a>

</td>

</tr>

<?php
}
?>

</table>

</div>

<?php

if(isset($_GET["editar"]))
{

$id = $_GET["editar"];

$consulta = mysqli_query(
$conexion,
"SELECT *
 FROM reserva
 WHERE id_reserva='$id'"
);

$reserva = mysqli_fetch_assoc(
$consulta
);

?>

<div class="card">

<h2>
🛠 Modificar Reserva
</h2>

<div class="notification-container" id="notificationContainer" style="margin-bottom:25px;"></div>

<form method="POST">

<input
type="hidden"
name="id_reserva"
value="<?php
echo $reserva["id_reserva"];
?>">

<label>
Nueva Cancha
</label>

<select
name="cancha"
required>

<?php

$canchas = mysqli_query(
$conexion,
"SELECT *
 FROM cancha"
);

while($c=mysqli_fetch_assoc($canchas))
{
?>

<option

value="<?php
echo $c["id_cancha"];
?>"

<?php

if(
$c["id_cancha"]
==
$reserva["id_cancha"]
)
{
echo "selected";
}

?>

>

<?php

echo $c["nombre"]
." - Bs. "
.$c["precio"];

?>

</option>

<?php
}
?>

</select>

<label>
Nueva Fecha
</label>

<input
type="date"
name="fecha"
required
value="<?php
echo $reserva["fecha"];
?>">

<label>
Nueva Hora
</label>

<select
name="hora">

<?php

$horas = array(
"08:00",
"09:00",
"10:00",
"11:00",
"12:00",
"13:00",
"14:00",
"15:00",
"16:00",
"17:00",
"18:00"
);

foreach($horas as $h)
{
?>

<option

<?php

if(
$reserva["hora"]
==
$h
)
{
echo "selected";
}

?>

>

<?php echo $h; ?>

</option>

<?php
}
?>

</select>

<br><br>

<input
type="submit"
name="guardar"
value="Guardar Cambios"
class="btn">

<input
type="reset"
value="Cancelar"
class="btn btn-danger">

</form>

</div>

<?php
}
?>

<div style="text-align:center; margin-top:20px;">

<a
href="../index.php"
class="btn">

🏠 Volver al Inicio

</a>

</div>

</div>

<div class="footer">

Sistema de Reserva de Canchas Deportivas

<br>

Proyecto de Ingeniería de Software

</div>

</body>
</html>