# VyOS 自動テストスクリプト集

VyOS の ISO イメージから Packer を用いて VyOS の VagrantBox を作成し、その VagrantBox を用いて一連のテストを実施するまでを自動化するためのスクリプト集です。

実施は不定期ですがテストの結果は [ここ](https://vyos-tester.ginzado.ne.jp/) で確認できます。

まだベータバージョンの ISO イメージの公開から自動でテストをするところまでは行けていませんが将来的には [ここ](http://dev.packages.vyos.net/iso/current/amd64/) に ISO イメージが公開された時にダウンロードからテストまでを自動化したいと考えています。

## 使い方

これらのスクリプトを利用するには以下の流れで行います。

1. VirtualBox を実行できる Ubuntu 16.04.2 LTS (Xenial Xerus) の環境を用意する
2. VirtualBox と Vagrant と Packer をインストールする
3. このリポジトリをクローンする
4. `iso/vyos-latest-amd64.iso` に VyOS の ISO イメージを置く
5. `vagrant/build_box.sh` を実行し VyOS の VagrantBox を作成する
5. `scripts/setup/vagrant_up.sh` を実行しテスト環境の仮想マシン群を起動する
6. `scripts/test` にあるテストスクリプトを実行する
7. テストが終わったら `scripts/setup/vagrant_destroy.sh` を実行し仮想マシンを削除する

## テストスクリプト

テストスクリプトは以下の通りです。

| テストスクリプト | 最近の状態 | 説明 |
|:-----------|:-----------:|:-------------|
| scripts/test/intnet_p.sh | [![Build Status](https://vyos-tester.ginzado.ne.jp/buildStatus/icon?job=TestIntNetP)](https://vyos-tester.ginzado.ne.jp/job/TestIntNetP/) | VagrantBox 間で正常に通信が可能か否かをテスト |
| scripts/test/intnet_n.sh | [![Build Status](https://vyos-tester.ginzado.ne.jp/buildStatus/icon?job=TestIntNetN)](https://vyos-tester.ginzado.ne.jp/job/TestIntNetN/) | VagrantBox 間で通信できてはならないところが通信できないようになっているかをテスト |

テストスクリプトはだいたい大きく 2 つの処理を行います。

1 つは VyOS 仮想マシンの設定です。 VyOS の設定は `vagrant ssh` コマンドを用いて設定スクリプトを流し込むことで行います。例えば `scripts/test/intnet_p.sh` の場合以下のように行います。

```
for vyos in vyos1 vyos2 vyos3 vyos4 vyos5
do
	echo "####"
	echo "#### setup ${vyos}"
	echo "####"
	vagrant ssh ${vyos} -c "/vagrant/scripts/vagrant/load_boot_config.vbash" || exit 1
	vagrant ssh ${vyos} -c "/vagrant/scripts/vagrant/common_init.vbash" || exit 1
	vagrant ssh ${vyos} -c "/vagrant/scripts/vagrant/intnet_p.vbash ${vyos}" || exit 1
	echo
done
```

VyOS の VagrantBox ではリポジトリのトップディレクトリが `/vagrant` として参照することができます。例えばリポジトリ内の `scripts/vagrant/common_init.vbash` というファイルは `/vagrant/scripts/vagrant/common_init.vbash` として参照できます。 `scripts/vagrant/common_init.vbash` は以下のようになっており VyOS のコマンドをそのまま実行しています。

```
source /opt/vyatta/etc/functions/script-template

configure

set protocols static route 10.0.0.0/8 blackhole
set protocols static route 172.16.0.0/12 blackhole
set protocols static route 192.168.0.0/16 blackhole
set protocols static route 169.254.0.0/16 blackhole

commit
```

テストスクリプトで行う処理の 2 つめは実際のテスト処理です。例えば `scripts/test/intnet_p.sh` では以下のような処理を行なっています。

```
EXITCODE=0
for i in 1 2 3 4 5
	do
	for j in 1 2 3 4 5
		do
		if [ ${i} -ge ${j} ]
		then
			continue
		fi
		for k in 1 2 3 4 5
		do
			echo "####"
			echo "#### ping vyos${i}:eth${k} -> vyos${j}:eth${k}"
			echo "####"
			vagrant ssh vyos${i} -c "/bin/ping -c 5 192.168.${k}.${j}" || EXITCODE=1
			echo
		done
	done
done

exit ${EXITCODE}
```

5 つある VyOS の 5 つの NIC で ping が正常に通るかをテストしています。 ping コマンドは 100% パケットロスの場合終了コードが 0 以外になります。1 つもパケットが通らなかった時は `EXITCODE=1` が実行され、このスクリプトの終了コードは 1 となります。

## テスト環境の構成

テスト環境は以下のような構成になっています。

```
              Vagrant 接続用 eth0
   |        |        |        |        |
  +-----+  +-----+  +-----+  +-----+  +-----+
  |vyos1|  |vyos1|  |vyos1|  |vyos1|  |vyos1|
  +-----+  +-----+  +-----+  +-----+  +-----+
   |||||    |||||    |||||    |||||    |||||  eth1ネット
   ||||+--------+--------+--------+--------+-----------
   ||||     ||||     ||||     ||||     ||||   eth2ネット
   |||+--------+--------+--------+--------+------------
   |||      |||      |||      |||      |||    eth3ネット
   ||+--------+--------+--------+--------+-------------
   ||       ||       ||       ||       ||     eth4ネット
   |+--------+--------+--------+--------+--------------
   |        |        |        |        |      eth5ネット
   +--------+--------+--------+--------+---------------
```
テストには 5 つの NIC(eth1 から eth5 まで) がアタッチされた 5 つの VyOS(vyos1 から vyos5 まで) を利用することができます。 VyOS には eth0 もアタッチされていますがこれは Vagrant 接続用のものでテストには利用できません。

