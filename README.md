#  GPU Fan Control

![GitHub](https://img.shields.io/github/license/tudo75/gpu-fan-control)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/tudo75/gpu-fan-control)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/tudo75/gpu-fan-control/Upload%20Python%20Package)

<div align="center">
    <img src="https://raw.githubusercontent.com/tudo75/gpu-fan-control/852a2ddd45e2cfcfe649cd5615865e453d42c118/gpu-fan-control.svg" alt="Icon" width="96px;" height="96px;"/>
</div>
GUI fan controller for Nvidia GPU

With this app you can set your preferred fan speed for Nvidia GPU (on Linux systems) without to use command line tools.

<b>Note:</b> Tested on GTX 460

<div align="center">
    <img src="https://raw.githubusercontent.com/tudo75/gpu-fan-control/dev/screenshot.png" alt="GUI Main Image" />
</div>

- [GPU Fan Control](#gpu-fan-control)
  - [Disclaimer](#disclaimer)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Usage](#usage)
  - [TODO](#todo)

## Disclaimer

NVIDIA is a registered trademark of NVIDIA Corporation.

Developers and app are not related to NVIDIA.

## Requirements

The appliction need:
  
- <code>nvidia-smi</code> package
- <code>nvidia-settings</code> package

## Installation

To install the app, open terminal and:

    git clone https://github.com/tudo75/gpu-fan-control.git
    cd gpu-fan-control
    meson setup build
    ninja -C build 
    ninja -C build install

## Usage

1. Open application through the created menu launcher or from terminal 

    gpu-fan-control

2. Click on: <i>"Initialize Nvidia Xconfig"</i>
4. If you receive a positive confirmation dialog then click on: <i>"Reboot"</i>.<br/>
   If you receive an error message, you should install the <code>nvidia-smi</code> and <code>nvidia-settings</code> packages and retry
1. After <i>Reboot</i> reopen app and set desired speed

## TODO

* [ ] Check Nvidia GPU index if there are multiple GPUs
* [ ] Handle multiple Nvidia GPU on same system
* [ ] Create a daemon/service to apply custom setting on boot
* [ ] Add a logging system
* [x] Replace nvidia-smi results with a custom panel
* [x] Add more graphic widgets to the dashboard
* [ ] Add help window as md or html file

