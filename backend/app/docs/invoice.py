from app import DocBase


class Invoice(DocBase):
    def commit(self, bag):
        pass

    def rollback(self, bag):
        pass

    def check(self, bag):
        pass
