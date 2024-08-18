from flask import Flask, request, jsonify
from flask_restful import Api, Resource
import sqlite3
from datetime import datetime

app = Flask(__name__)
api = Api(app)

DB_PATH = '/var/lib/aquarium_monitoring/aquarium.db'

def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

class WaterTemperature(Resource):
    def get(self):
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = dict_factory
        cursor = conn.cursor()

        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')

        if start_date and end_date:
            query = '''
            SELECT * FROM water_temperature 
            WHERE timestamp BETWEEN ? AND ?
            ORDER BY timestamp DESC
            '''
            cursor.execute(query, (start_date, end_date))
        else:
            query = 'SELECT * FROM water_temperature ORDER BY timestamp DESC'
            cursor.execute(query)

        results = cursor.fetchall()
        conn.close()

        return jsonify(results)

api.add_resource(WaterTemperature, '/water_temperature')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)