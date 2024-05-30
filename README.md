<p align="center">
<picture>
<img width="160" height="160"  alt="XPanel" src="https://github.com/iPmartNetwork/iPmart-SSH/blob/main/images/logo.png">
</picture>
  </p> 
<p align="center">
<h1 align="center"/>WGDashboard</h1>
<h6 align="center"> پنل مدیریتی وایرگارد <h6>
</p>


## پیش نیاز

اوبنتو 22 و بالاتر

## آموزش و مراحل نصب


ابتدا با کد ستوری زیر سرور را اپدیت کنید و وایرگارد را نصب کنید 
```
apt update -y && apt install wireguard -y
```

با کد دستوری زیر کلید پرایویت بسازید و در یک جا کپی کنید

```
wg genkey | sudo tee /etc/wireguard/server_private.key
```


کد نمایش اینترفیس پیشفرض ( ممکن هست در دیتا سنترهای مختلف متفاوت باشد (eth0)

```
ip route list default
```




با کد دستوری زیر وارد مسیر فایل کانفیگ وایرگارد شوید

```
nano /etc/wireguard/wg0.conf
```





















