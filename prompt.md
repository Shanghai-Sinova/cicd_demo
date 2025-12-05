## prompt 
增加 fastapi fastmcp langchang 1.1 agentscope 使用uv 并且使用清华源, 编写一个langchain 
  agent fastapi fastmcp 运行在http server 5000端口上的一个helloworld agent程序 有api  同样的 使用gin go狼最新版
  本的也编写一个 同样的 使用 tanstack的start框架制作一个ssr 也是如此 使用vite + rolldown +pnpm monorepo  都查询
  他们的最新版本 rust的话使用salvo框架 . 查询使用语言的最新版本 最新框架版本. 然后每个都要创建dockerfile 注意要
  求为最小镜像遵循最佳实践 注意要增加 国内的registry mirrors. 然后要使用kcl 和 tomni来生成对应的 k8s的chart文件


 推送镜像
增加github action的workflow 每个语言创建的项目都要编写一个编译为docker 镜像 并且推送到镜像仓库 镜像仓库的地址为
docker push sinova-cn-beijing.cr.volces.com/buka/[[镜像仓库]:[镜像版本号]
1、docker login --username=alexhe@53804650 buka-cn-shanghai.cr.volces.com
2、docker tag [ImageId] buka-cn-shanghai.cr.volces.com/buka/buka:[镜像版本号]
3、docker push buka-cn-shanghai.cr.volces.com/buka/buka:[镜像版本号]
密码为iloveBuka123

对应的charts 也要可以推送的
helm 3.7 版本后
1、helm registry login --username=alexhe@53804650 buka-cn-shanghai.cr.volces.com
2、helm package [Chart 名称] --version [Chart 版本号]
3、helm push [[Chart 名称]-[Chart 版本号].tgz] oci://buka-cn-shanghai.cr.volces.com/buka


node使用25的镜像版本 不同的项目使用不同的端口暴露 可以是5000到 5010这
  样
uv使用最新版本


##  dockerfile源

在dockerfile里 python go pnpm rust里都加上中国的源 例如python 清华源
  golang 使用goproxy.cn的源头 pnpm 使用淘宝源头 rust 使用rsproxy.cn的源
  头
## vite rolldown用这个
https://vite.dev/guide/rolldown
