PACKAGE_SRC=https://www.python.org/ftp/python/3.12.8/Python-3.12.8.tgz
PACKAGE_NAME=python

build () {
	mkdir -p $PACKAGE_NAME
	cd $PACKAGE_NAME
	wget $PACKAGE_SRC
	tar xf Python-3.12.8.tgz
	cd Python-3.12.8
	./configure --prefix=$PREFIX
	make
	make install
	cd ..
	rm -rf Python-3.12.8
}