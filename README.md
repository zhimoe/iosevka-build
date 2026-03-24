# iosevka-build
构建自己的 iosekva 字体。

1 维护  private-build-plans.toml
2 构建镜像 git clone --depth 1 https://github.com/be5invis/Iosevka.git && cd Iosevka && docker build -t iosevka-builder docker
3 构建字体 
docker run -it --rm -e SOURCE=main -v $PWD:/work iosevka-builder ttf::Iosevka --jCmd=6 

ttf::<plan> 是  private-build-plans.toml 里面的 plan name


# sarasa mono build
1. scripts:
```
git clone --depth 1 https://github.com/be5invis/Sarasa-Gothic.git
brew install node ttfautohint
python -m venv .venv
source .venv/bin/activate
    python -m pip install afdko
```

2. copy your iosevka ttf to sources
3. modify config.json from sarasa-build-config.json
4. run: npm run build ttf