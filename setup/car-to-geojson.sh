#!/bin/bash
jq -c '
    .features[] |
    ({
        type: "Feature",
        properties: {
        car_id: .id,
        type: "Property boundary",
        producer_cpf_cnpj: [.properties.ctd_json_imovel | fromjson | .proprietariosPosseirosConcessionarios[] | .cpfCnpj],
        producer_estab_name: .properties.nom_imovel,
        property_code: .properties.cod_imovel,
        protocol_code: .properties.cod_protocolo,
        protocol_date: .properties.dat_protocolo,
        creation_date: .properties.dat_criacao,
        update_date: .properties.dat_atualizacao
        },
        geometry
    }),
    ({
        type: "Feature",
        properties: {
        car_id: .id,
        type: "Legal reserve (proposed)",
        producer_cpf_cnpj: [.properties.ctd_json_imovel | fromjson | .proprietariosPosseirosConcessionarios[] | .cpfCnpj],
        producer_estab_name: .properties.nom_imovel,
        property_code: .properties.cod_imovel,
        protocol_code: .properties.cod_protocolo,
        protocol_date: .properties.dat_protocolo,
        creation_date: .properties.dat_criacao,
        update_date: .properties.dat_atualizacao
        },
        geometry: .properties.ctd_json_imovel | fromjson.geo[] | select(.tipo == "ARL_PROPOSTA").geoJson
    } | select(.geometry != [])),
    ({
        type: "Feature",
        properties: {
        car_id: .id,
        type: "Legal reserve (actual)",
        producer_cpf_cnpj: [.properties.ctd_json_imovel | fromjson | .proprietariosPosseirosConcessionarios[] | .cpfCnpj],
        producer_estab_name: .properties.nom_imovel,
        property_code: .properties.cod_imovel,
        protocol_code: .properties.cod_protocolo,
        protocol_date: .properties.dat_protocolo,
        creation_date: .properties.dat_criacao,
        update_date: .properties.dat_atualizacao
        },
        geometry: .properties.ctd_json_imovel | fromjson.geo[] | select(.tipo == "ARL_TOTAL").geoJson
    } | select(.geometry != [])),
    ({
        type: "Feature",
        properties: {
        car_id: .id,
        type: "Permanent preservation area",
        producer_cpf_cnpj: [.properties.ctd_json_imovel | fromjson | .proprietariosPosseirosConcessionarios[] | .cpfCnpj],
        producer_estab_name: .properties.nom_imovel,
        property_code: .properties.cod_imovel,
        protocol_code: .properties.cod_protocolo,
        protocol_date: .properties.dat_protocolo,
        creation_date: .properties.dat_criacao,
        update_date: .properties.dat_atualizacao
        },
        geometry: .properties.ctd_json_imovel | fromjson.geo[] | select(.tipo == "APP_TOTAL").geoJson
    } | select(.geometry != []))'
