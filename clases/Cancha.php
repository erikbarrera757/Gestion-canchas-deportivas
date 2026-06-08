<?php

class Cancha
{
    public $id_cancha;
    public $nombre;
    public $tipo;

    public function __construct(
        $id_cancha,
        $nombre,
        $tipo
    )
    {
        $this->id_cancha=$id_cancha;
        $this->nombre=$nombre;
        $this->tipo=$tipo;
    }
}

?>