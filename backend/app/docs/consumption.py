from app import DocBase


class Consumption(DocBase):
    def commit(self, bag):
        pass

    def rollback(self, bag):
        pass

    def check(self, bag):
        pass
