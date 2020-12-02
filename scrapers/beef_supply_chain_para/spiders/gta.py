import scrapy, json, random

class GtaSpider(scrapy.Spider):
    name = 'gta'

    def start_requests(self):
        gta_series       = self.settings.get('SERIES')
        gta_number_start = self.settings.getint('START')
        gta_number_end   = self.settings.getint('END') + 1
        
        gta_numbers = list(range(gta_number_start, gta_number_end))
        random.shuffle(gta_numbers)

        for gta_number in gta_numbers:
            yield scrapy.Request(
                method   = 'POST',
                url      = 'https://siapec3.adepara.pa.gov.br/siapec3/services/rest/gta/CGAAInInPPOna/',
                body     = json.dumps({
                    'serieGta': gta_series,
                    'numeroGta': str(gta_number).zfill(6)}),
                headers  = {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'},
                callback = self.parse)
    
    def parse(self, response):
        yield {
            'request': json.loads(response.request.body),
            'response': json.loads(response.text)
        }
