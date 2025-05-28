module github.com/buptczq/WinCryptSSHAgent

go 1.23.0

replace github.com/Microsoft/go-winio => github.com/buptczq/go-winio v0.4.16-1

replace github.com/lxn/walk => github.com/tantra35/walk v0.0.0-20240330122720-676edb3df880

replace github.com/hattya/go.notify v0.0.0-20200507123844-18670158b53e => github.com/buptczq/go.notify v0.0.0-20210108030838-37adc71f67d9

require (
	github.com/Microsoft/go-winio v0.4.16
	github.com/bi-zone/wmi v1.1.4
	github.com/fullsailor/pkcs7 v0.0.0-20190404230743-d7302db945fa
	github.com/hattya/go.notify v0.0.0-20200507123844-18670158b53e
	github.com/jessevdk/go-flags v1.5.0
	github.com/kayrus/putty v1.0.5
	github.com/linuxkit/virtsock v0.0.0-20180830132707-8e79449dea07
	github.com/lxn/walk v0.0.0-20210112085537-c389da54e794
	golang.org/x/crypto v0.38.0
	golang.org/x/sys v0.33.0
)
