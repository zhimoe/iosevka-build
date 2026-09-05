# iosevka-build

构建自己的 Iosevka 字体。

## 1. 维护构建配置

编辑项目根目录下的 `private-build-plans.toml`。

`ttf::<plan>` 中的 `<plan>` 是该文件里的 plan name，例如本项目使用 `ttf::Iosevka`。

## 2. 构建 Docker 镜像

```bash
git clone --depth 1 https://github.com/be5invis/Iosevka.git && cd Iosevka && docker build -t iosevka-builder docker && cd ..
```

> 这个镜像只包含构建环境和 `/build.sh`，不包含上面 clone 的 Iosevka 源码。

## 3. 构建字体

### 方式一：直接使用本地已 clone 的源码

适合本项目；源码和 `node_modules` 都会保留在 `./Iosevka` 中，不会重复下载源码。

```bash
docker run -it --rm \
  -v "$PWD/Iosevka:/work" \
  -v "$PWD/private-build-plans.toml:/work/private-build-plans.toml:ro" \
  --entrypoint bash \
  iosevka-builder \
  -lc '[ -d node_modules ] || npm install; npm run build -- ttf::Iosevka --jCmd=6'
```

构建结果在 `./Iosevka/dist`。

### 方式二：重新下载源码构建

```bash
docker run -it --rm -e SOURCE=main -v $PWD:/work iosevka-builder ttf::Iosevka --jCmd=6 
```
构建结果在 `./dist`。
ttf::<plan> 是  private-build-plans.toml 里面的 plan name

参考：[Iosevka 官方 Docker 构建说明](https://github.com/be5invis/Iosevka/blob/main/docker/README.md)
