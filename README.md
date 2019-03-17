# SRLibras
Sistema de Reconhecimento de Libras

Este é um projeto de soletração do alfabeto manual de Libras (Língua Brasileira de Sinais) para PT-BR.

# Requisitos
- Flutter para executar o aplicativo para smartphones.
- Seguir estes passos - https://firebase.google.com/docs/flutter/setup?hl=pt-BR - para conectar o Firebase ao projeto. Isso é necessário para que o modelo da rede neural execute corretamente. Como o projeto já foi configurado para o Firebase, o necessário é copiar o seu próprio arquivo `google-services.json` para a pasta `android/app`.

- Python 3 (recomenda-se instalar via Anaconda), instalando-se os pacotes necessários via `pip install` ou `conda install`. Exemplo: `pip install keras`.
- Os códigos da pasta `classificadores` estão escritos em Python através do `Jupyter`, assim, no terminal, deve-se executar o comando `jupyter notebook` para iniciar o `jupyter`.
- IDE Arduino e em seguida instalar a biblioteca do ESP32 para executar o código do microcontrolador.