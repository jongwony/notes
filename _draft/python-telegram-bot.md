install amazon linux

## amazon linux pip problem

http://stackoverflow.com/questions/34871994/failed-in-sudo-pip

sudo which pip
sudo vim /usr/bin/pip
pip==6.1.1 -> latest version

sudo easy_install --upgrade pip


## virtual env

sudo yum install git
pip freeze
git clone https://github.com/python-telegram-bot/python-telegram-bot
cd python-telegram-bot/
virtualenv venv
. venv/bin/activate

## new pip
pip install --upgrade pip
python setup.py install
(pip freeze > requirement.txt)

## Or

pip install python-telegram-bot --upgrade

## Getting started

https://github.com/python-telegram-bot/python-telegram-bot#getting-started
