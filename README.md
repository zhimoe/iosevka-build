# iosevka-build
构建自己的 iosekva 字体。

1 维护  private-build-plans.toml

2 构建镜像 
```bash
git clone --depth 1 https://github.com/be5invis/Iosevka.git && cd Iosevka && docker build -t iosevka-builder docker
cd ..
```

3 构建字体 
```bash
docker run -it --rm -e SOURCE=main -v $PWD:/work iosevka-builder ttf::Iosevka --jCmd=6 
```
ttf::<plan> 是  private-build-plans.toml 里面的 plan name
