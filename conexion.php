<?php

$conexion = mysqli_connect(
    "localhost",
    "root",
    "",
    "reserva_canchas"
);

if(!$conexion)
{
    die("Error de conexión");
}

?>