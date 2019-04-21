import unittest

from app.keys import TYPE
from app.service.doc import get_view, save


class MyTest(unittest.TestCase):
    def test(self):
        bag = {TYPE: 'Invoice'}

        ret = get_view(bag)

        save(bag)

        self.assertEqual(ret['view'], 'InvoiceView')
