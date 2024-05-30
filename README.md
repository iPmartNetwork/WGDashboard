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

## آموزش و مراحل نصب وایرگارد


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
- کلید پرایوت  که ساخته بودید را در (( محل کد کلید پرایویت )) قرار دهید



## مراحل نصب پنل مدیریتی وایرگارد


کد های دستوری زیر را خط به خط وارد کنید 


```
apt install git
```
```
git clone https://github.com/iPmartNetwork/WGDashboard.git
```
```
cd WGDashboard
```
```
mv src /root/
```
```
cd
```
```
rm -rf WGDashboard
```
```
apt-get -y install python3-pip
```
```
apt install gunicorn -y
```
```
cd src
```
```
sudo chmod u+x wgd.sh
```
```
pip install -r requirements.txt
```
```
sudo ./wgd.sh install
```
```
sudo chmod -R 755 /etc/wireguard
```
```
./wgd.sh start
```



- به پنل خودتون با http://Your_Server_IP:2249 وارد شوید.
-  نام کاربری admin و رمزعبور admin است
- برای تانل از تانل رتهول استفاده کنید که در همین گیت هاب موجود میباشد.
- درصورت تانل، داخل تنظیمات Peer Remote Endpoint را به IP ایران تغییر دهید
- اگر به مشکل internal error در زمان لود پنل خوردید، سرور را یک بار ریبوت کنید و سپس دستور زیر را بزنید


```
cd src && ./wgd.sh restart
```


- برای اینکه دیگر مشکل بالا نیامدن پنل بعد از ریبوت یا ریستارت نداشته باشین با کد های پایین یک سرویس ایجاد کنید مراحا را خط به خط انجام دهید.

```
nano /etc/systemd/system/iPmart.service
```


 ```
[Unit]
After=network.service

[Service]
WorkingDirectory=/root/src/
ExecStart=/usr/bin/python3 /root/src/dashboard.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target

```

```
sudo chmod 664 /etc/systemd/system/iPmart.service
sudo systemctl daemon-reload
sudo systemctl enable iPmart.service
sudo systemctl start iPmart.service
sudo systemctl status iPmart.service
```





# تلگرام

[@ipmart_network](https://t.me/ipmart_network)

[@iPmart Group](https://t.me/ipmartnetwork_gp)




 # حمایت از ما :hearts:
حمایت های شما برای ما دلگرمی بزرگی است<br> 
<p align="left">
<a href="https://plisio.net/donate/kB7QU7f7" target="_blank"><img src="https://plisio.net/img/donate/donate_light_icons_mono.png" alt="Donate Crypto on Plisio" width="240" height="80" /></a><br>
	
|                    TRX                   |                       BNB                         |                    Litecoin                       |
| ---------------------------------------- |:-------------------------------------------------:| -------------------------------------------------:|
| ```TJbTYV1fFo2485sYMyajxGPLFzxmNmPrNA``` |  ```0x4af3de9b303a8d43105e284823d95b4c600961a3``` | ```MPrkzFiNtw4Rg67bbZB6gCxa9LV87orABM``` |	

</p>	




<p align="center">
<picture>
<img width="160" height="160"  alt="XPanel" src="https://github.com/iPmartNetwork/iPmart-SSH/blob/main/images/logo.png">
</picture>
  </p> 













