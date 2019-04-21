# coding=utf-8
from datetime import datetime

from flask import g

from app import DocBase, controller, PostgresDatabase, ID, orm_to_json
from app.model import db


class Sale(DocBase):
    description = "Продажа"

    def commit(self, bag):
        pg_db = PostgresDatabase()
        bag['type'] = 'Document'
        bag['document_status'] = 'committed'
        _id, _rev = pg_db.store(bag)

        amount = 0
        for product in bag['data']['products']:
            operation_data = {
                "branch_id": bag['branch_id'],
                "document_id": _id,
                "product_id": product['product_id'],
                "unit_id": product['unit_id'],
                "quantity": product['quantity'] * -1,
                "currency_id": bag['data']['currency_id'],
                "quote_unit_price": product['quote_unit_price'],
                "total_cost": product['total_cost'],
                "additional_cost": product.get('additional_cost', 0),
                "delivery_date": bag['data'].get('delivery_date', None),
                "is_due": bag['data'].get('is_due', False),
                "due_date": bag['data'].get('due_date', None),
                "contractor_id": bag['data']['contractor_id'],
                "comment": u'{}\n{}'.format(bag['title'], bag.get('short_desc', u''))
            }

            controller.call('operation.put', operation_data)

            amount += product['total_cost'] + product.get('additional_cost', 0)

        payment_data = {
            "branch_id": bag['branch_id'],
            "document_id": _id,
            "amount": amount,
            "currency_id": bag['data']['currency_id'],
            "payment_date": datetime.now(),
            "payment_direction": 'they_to_us' if 'is_due' in bag['data'] and bag['data'][
                                                                                 'is_due'] is True else 'we_give_them',
            "archive": False,
            "payment_type": 'cash' if 'is_due' in bag['data'] and bag['data']['is_due'] is True else 'debt',
            "data": {
                "contractor_id": bag['data']['contractor_id'],
                "comment": u'{}\n{}'.format(bag['title'], bag.get('short_desc', u''))
            }
        }

        controller.call('accounting.put', payment_data)

        return {"id": _id, "rev": _rev}

    def rollback(self, bag):
        pg_db = PostgresDatabase()
        document = orm_to_json(g.tran.query(db.Document).filter_by(_deleted='infinity', _id=bag[ID]).one())
        document['type'] = 'Document'
        document['document_status'] = 'canceled'
        _id, _rev = pg_db.store(document)

        for payment in g.tran.query(db.Payments).filter_by(_deleted='infinity', document_id=_id).all():
            payment = orm_to_json(payment)
            payment['payment_status'] = 'canceled'
            controller.call('accounting.put', payment)

        for operation in g.tran.query(db.Operations).filter_by(_deleted='infinity', document_id=_id).all():
            operation = orm_to_json(operation)
            operation['operation_status'] = 'canceled'
            controller.call('operation.put', operation)

    def check(self, bag):
        temp_bag = {
            "document_type": bag["document_type"],
            "document_status": bag["document_status"] if "document_status" in bag else 'draft',
            "company_id": bag["company_id"] if "company_id" in bag else g.session["company_id"],
            "branch_id": bag["branch_id"],
            "title": bag["title"],
            "approval": {
                "required": bag["approval"]["required"]
            },
            "data": {
                "products": []
            }
        }

        if "_id" in bag:
            temp_bag["_id"] = bag["_id"]
        if "_rev" in bag:
            temp_bag["_rev"] = bag["_rev"]

        if "short_desc" in bag:
            temp_bag["short_desc"] = bag["short_desc"]
        if "approval_type" in bag["approval"] and bag["approval"]["required"] is True:
            temp_bag["approval"]["approval_type"] = bag["approval"]["approval_type"]
        if "roles_id" in bag["approval"] and bag["approval"]["required"] is True:
            temp_bag["approval"]["roles_id"] = bag["approval"]["roles_id"]
        if "approval_roles" in bag["approval"] and bag["approval"]["required"] is True:
            temp_bag["approval"]["approval_roles"] = []
            for approval_role in bag["approval"]["approval_roles"]:
                temp_approval_role = {
                    "role_id": approval_role["role_id"]
                }
                if "approved" in approval_role:
                    temp_approval_role["approved"] = approval_role["approved"]
                if "approval_users" in approval_role:
                    temp_approval_role["approval_users"] = []
                    for approval_user in approval_role["approval_users"]:
                        temp_approval_user = {
                            "user_id": approval_user["user_id"],
                            "approved": approval_user["approved"]
                        }
                        temp_approval_role["approval_users"].append(temp_approval_user)
                temp_bag["approval"]["approval_roles"].append(temp_approval_role)
        if "user_id" in bag["data"]:
            temp_bag["data"]["user_id"] = bag["data"]["user_id"]
        if "executor_id" in bag["data"]:
            temp_bag["data"]["executor_id"] = bag["data"]["executor_id"]
        if "contractor_id" in bag["data"]:
            temp_bag["data"]["contractor_id"] = bag["data"]["contractor_id"]
        if "currency_id" in bag["data"]:
            temp_bag["data"]["currency_id"] = bag["data"]["currency_id"]
        if "delivery_date" in bag["data"]:
            temp_bag["data"]["delivery_date"] = bag["data"]["delivery_date"]
        if "is_due" in bag["data"]:
            temp_bag["data"]["is_due"] = bag["data"]["is_due"]
        if "due_date" in bag["data"]:
            temp_bag["data"]["due_date"] = bag["data"]["due_date"]
        if "date" in bag["data"]:
            temp_bag["data"]["date"] = bag["data"]["date"]
        if "comment" in bag["data"]:
            temp_bag["data"]["comment"] = bag["data"]["comment"]

        for product in bag["data"]["products"]:
            temp_product = {
                "product_id": product["product_id"],
                "unit_id": product["unit_id"],
                "quantity": product["quantity"]
            }

            if "rule_id" in product:
                temp_product["rule_id"] = product["rule_id"]
            if "quote_unit_price" in product:
                temp_product["quote_unit_price"] = product["quote_unit_price"]
            if "additional_cost" in product:
                temp_product["additional_cost"] = product["additional_cost"]
            if "total_cost" in product:
                temp_product["total_cost"] = product["total_cost"]
            if "comment" in product:
                temp_product["comment"] = product["comment"]

            temp_bag["data"]["products"].append(temp_product)
        bag.clear()
        for item in temp_bag:
            bag[item] = temp_bag[item]
