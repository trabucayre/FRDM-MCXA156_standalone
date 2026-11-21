# FRDM-MCXA156_standalone
PoC for FRDM-MCXA156 without MCUXpresso nor VSCode

## Repositories version

| Name / URL                                                                 | version / branch                                         |
|----------------------------------------------------------------------------|----------------------------------------------------------|
| [mcu-sdk-cmsis](https://github.com/nxp-mcuxpresso/mcu-sdk-cmsis.git)       | dd88dfb6c36140c3f48a0aa545d386deae29e6c7 / 26.09.00-pvw2 |
| [mcux-component](https://github.com/nxp-mcuxpresso/mcux-component.git)     | 12153a553bd811341fb5d9744e8dc33d32e89cfc / 26.09.00      |
| [mcux-devices-mcx](https://github.com/nxp-mcuxpresso/mcux-devices-mcx.git) | 7c0e68e9094e3943edbe1c9bf68305556adaa2c8 / 26.09.00      |
| [mcuxsdk-core](https://github.com/nxp-mcuxpresso/mcuxsdk-core.git)         | c6f4223f45fdab59509f25ee3ea63a71bd29d8aa / 26.09.00      |

## Prerequisites

The `arm-none-eabi-gcc` cross-compiler is required:
```bash
sudo apt install binutils-arm-none-eabi gcc-arm-none-eabi picolibc-arm-none-eabi
```

The flash step uses *pyOCD*
```bash
pip3 install --user --break-system-packages pyocd
```
