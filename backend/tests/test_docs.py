# coding=utf-8
from unittest2 import TestCase

from app import DocBase


class DocsTests(TestCase):
    def test_01_list(self):
        docs = DocBase.all()
        self.assertIsInstance(docs, list)
        self.assertIn("Sale", [d['id'] for d in docs])
