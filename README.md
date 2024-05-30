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

اوبنتو 20 و بالاتر

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


در داخلفایل متن زیر را کپی و پیست کنید

```
[Interface]
Address = 110.20.0.1/24
PostUp = iptables -I INPUT -p udp --dport 51820 -j ACCEPT
PostUp = iptables -I FORWARD -i eth0 -o wg0 -j ACCEPT
PostUp = iptables -I FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostUp = ip6tables -I FORWARD -i wg0 -j ACCEPT
PostUp = ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport 51820 -j ACCEPT
PostDown = iptables -D FORWARD -i eth0 -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PostDown = ip6tables -D FORWARD -i wg0 -j ACCEPT
PostDown = ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 51820
PrivateKey = محل کد کلید پرایویت بالا گرفتیم
SaveConfig = true
```

- پورت وایرگارد در اینجا 51820 است، میتوانید پورت دیگری انتخاب کنید
- کلید پرایوت  که ساخته بودید را به در (( محل کد کلید پرایویت )) قرار دهید






















