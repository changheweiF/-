下载者两个文件，放在对应的位置

"/etc/auto_login_daemon.sh"

“/etc/init.d/auto_login”

添加执行权限
```shell
chmod +x /etc/init.d/auto_login
chmod +x /etc/auto_login_daemon.sh
```
使用方法：
1. 填入参数
2. 使用语句运行开机自启动
```shell
   /etc/init.d/auto_login enable
```
3. 开始运行
```shell
   /etc/init.d/auto_login start
```
