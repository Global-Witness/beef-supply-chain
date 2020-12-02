import scrapy, json

class CarSpider(scrapy.Spider):
    name = 'car'

    def start_requests(self):
        car_number_start = self.settings.getint('START')
        car_number_end   = self.settings.getint('END') + 1

        for car_id in range(car_number_start, car_number_end):
            yield scrapy.Request(
                url = 'http://car.semas.pa.gov.br/geoserver/secar-pa/wfs?service=wfs&version=2.0.0&request=GetFeature&typeName=secar-pa:imovel&outputFormat=json&featureID=imovel.' + str(car_id),
                callback = self.parse)

    def parse(self, response):
        yield json.loads(response.text)
