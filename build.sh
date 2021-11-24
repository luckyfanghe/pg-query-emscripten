# install git
if ! [ -x "$(command -v git)" ]; then
    apt-get install git
fi

# install emsdk
if ! [ -x "$(command -v emcc)" ]; then
    echo 'install emsdk'
    rm -rf emsdk
    git clone https://github.com/emscripten-core/emsdk.git
    cd emsdk
    git pull
    ./emsdk install latest  # 3.0.0
    ./emsdk activate latest
    source ./emsdk_env.sh
fi

make