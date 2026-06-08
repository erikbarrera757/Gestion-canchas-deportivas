<?php

class Cliente
{
    public $id_cliente;
    public $nombre;
    public $telefono;

    public function __construct(
        $id_cliente,
        $nombre,
        $telefono
    )
    {
        $this->id_cliente=$id_cliente;
        $this->nombre=$nombre;
        $this->telefono=$telefono;
    }
}

?>