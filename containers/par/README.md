<div align='center'>
    <img alt='Paragraph formatting icon' src='par.png' width='128'>
</div>

<div align='center'><h1>Paragraph formatter</h1></div>
<div align='center'><code>par</code> in a jar</div>
<br>
<br>

## Prerequisites

Make sure you have whatever container runtime and wrapper is trending at the
moment. Tested with the following :

- Docker
- Podman

## Installing

It's as easy as

    docker build -t par -f Dockerfile

and as simple as

    podman build -t par -f Dockerfile

## Usage

    cat <file> | docker run --rm -i par <par arguments>
    cat <file> | podman run --rm -i par <par arguments>
