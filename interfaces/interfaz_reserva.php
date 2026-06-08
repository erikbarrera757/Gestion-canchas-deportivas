<?php

include("../conexion.php");

$mensaje = "";
$tipo_mensaje = "";

if(isset($_POST["confirmar"]))
{
    $cliente = $_POST["cliente"];
    $tipo = $_POST["tipo"];
    $fecha = $_POST["fecha"];
    $hora = $_POST["hora"];
    $cancha = $_POST["cancha"];

    $productos = array();

    if(isset($_POST["balon"]))
    {
        $productos[] = "Balon";
    }

    if(isset($_POST["bebida"]))
    {
        $productos[] = "Bebida";
    }

    if(isset($_POST["arbitro"]))
    {
        $productos[] = "Arbitro";
    }

    $verificar = "
    SELECT *
    FROM reserva
    WHERE id_cancha='$cancha'
    AND fecha='$fecha'
    AND hora='$hora'
    ";

    $resultado = mysqli_query(
        $conexion,
        $verificar
    );

    if(mysqli_num_rows($resultado) > 0)
    {
        $mensaje = "La cancha ya se encuentra reservada.";
        $tipo_mensaje = "error";
    }
    else
    {
        $precioCancha = 0;

        $consultaCancha = mysqli_query(
            $conexion,
            "SELECT precio
             FROM cancha
             WHERE id_cancha='$cancha'"
        );

        if($filaCancha = mysqli_fetch_assoc($consultaCancha))
        {
            $precioCancha = $filaCancha["precio"];
        }

        $total = $precioCancha;

        foreach($productos as $producto)
        {
            $consultaProducto = mysqli_query(
                $conexion,
                "SELECT precio
                 FROM producto
                 WHERE nombre='$producto'"
            );

            if($filaProducto = mysqli_fetch_assoc($consultaProducto))
            {
                $total += $filaProducto["precio"];
            }
        }

        mysqli_query(
            $conexion,
            "INSERT INTO reserva
            (
                id_cliente,
                id_cancha,
                fecha,
                hora,
                total
            )
            VALUES
            (
                '$cliente',
                '$cancha',
                '$fecha',
                '$hora',
                '$total'
            )"
        );

        $idReserva = mysqli_insert_id($conexion);

        foreach($productos as $producto)
        {
            $buscarProducto = mysqli_query(
                $conexion,
                "SELECT id_producto
                 FROM producto
                 WHERE nombre='$producto'"
            );

            if($fila = mysqli_fetch_assoc($buscarProducto))
            {
                mysqli_query(
                    $conexion,
                    "INSERT INTO detalle_reserva
                    (
                        id_reserva,
                        id_producto
                    )
                    VALUES
                    (
                        '$idReserva',
                        '".$fila["id_producto"]."'
                    )"
                );
            }
        }

        $mensaje = "Reserva registrada correctamente.";
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

<title>Registrar Reserva</title>

<link rel="stylesheet"
href="../css/estilos.css">

</head>

<body>

<header>

<h1>
⚽ REGISTRO DE RESERVAS
</h1>

<p>
Sistema de Gestión de Canchas Deportivas
</p>

</header>

<div class="contenedor">

<?php

if($mensaje!="")
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
📝 Registrar Nueva Reserva
</h2>

<div class="notification-container" id="notificationContainer" style="margin-bottom:25px;"></div>

<form method="POST">

<label>
Cliente
</label>

<select
name="cliente"
required>

<?php

$clientes = mysqli_query(
$conexion,
"SELECT * FROM cliente"
);

while($c = mysqli_fetch_assoc($clientes))
{
?>

<option
value="<?php echo $c["id_cliente"]; ?>">

<?php
echo $c["nombre"] .
" " .
$c["apellido"];
?>

</option>

<?php
}
?>

</select>

<label>
Tipo de Cancha
</label>

<select
name="tipo"
required>

<option value="Futbol">
⚽ Fútbol
</option>

<option value="Futsal">
🥅 Futsal
</option>

<option value="Voley">
🏐 Vóley
</option>

<option value="Basquet">
🏀 Básquet
</option>

</select>

<label>
Fecha
</label>

<input
type="date"
name="fecha"
required>

<label>
Hora
</label>

<select
name="hora">

<option>08:00</option>
<option>09:00</option>
<option>10:00</option>
<option>11:00</option>
<option>12:00</option>
<option>13:00</option>
<option>14:00</option>
<option>15:00</option>
<option>16:00</option>
<option>17:00</option>
<option>18:00</option>

</select>

<label>
Cancha
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

while($ca = mysqli_fetch_assoc($canchas))
{
?>

<option
value="<?php echo $ca["id_cancha"]; ?>">

<?php

echo $ca["nombre"] .
" - Bs. " .
$ca["precio"];

?>

</option>

<?php
}
?>

</select>

<h3>
🎁 Productos Adicionales
</h3>

<input
type="checkbox"
name="balon">

Balón Deportivo

<br><br>

<input
type="checkbox"
name="bebida">

Bebida Energética

<br><br>

<input
type="checkbox"
name="arbitro">

Servicio de Árbitro

<br><br>

<input
type="submit"
name="confirmar"
value="Confirmar Reserva"
class="btn">

<input
type="reset"
value="Cancelar"
class="btn btn-danger">

<a href="../index.php"
class="btn"
style="margin-left:12px;">
⬅ Volver al Inicio
</a>

</form>

</div>

<div class="card">

<h2>
🏟 Canchas Disponibles
</h2>

<table>

<tr>

<th>ID</th>
<th>Nombre</th>
<th>Tipo</th>
<th>Precio</th>

</tr>

<?php

$lista = mysqli_query(
$conexion,
"SELECT * FROM cancha"
);

while($fila = mysqli_fetch_assoc($lista))
{
?>

<tr>

<td>
<?php echo $fila["id_cancha"]; ?>
</td>

<td>
<?php echo $fila["nombre"]; ?>
</td>

<td>
<?php echo $fila["tipo"]; ?>
</td>

<td>
Bs.
<?php echo $fila["precio"]; ?>
</td>

</tr>

<?php
}
?>

</table>

</div>

</div>

<div class="footer">

Proyecto Ingeniería de Software

</div>

</body>
</html>