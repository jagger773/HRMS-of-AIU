# coding=utf-8
from app import DocBase


class Cashier(DocBase):
    description = "Касса"

    def __init__(self):
        super(Cashier, self).__init__()

    def rollback(self, bag):
        pass

    def commit(self, bag):
        pass

    def check(self, bag):
        pass
