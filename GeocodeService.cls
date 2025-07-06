public with sharing class GeocodeService {
    
    // Nominatim (OpenStreetMap) API를 사용한 주소 지오코딩
    @future(callout=true)
    public static void geocodeOpportunities(Set<Id> opportunityIds) {
        // 지오코딩할 Opportunity 조회
        List<Opportunity> opportunities = [
            SELECT Id, BillingStreet__c, Location__c, Geocoding_Status__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
            AND BillingStreet__c != null
        ];
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for (Opportunity opp : opportunities) {
            try {
                // Nominatim API 호출
                HttpRequest req = new HttpRequest();
                String endpoint = 'https://nominatim.openstreetmap.org/search';
                String query = '?format=json&limit=1&countrycodes=kr'; // 한국으로 제한
                query += '&q=' + EncodingUtil.urlEncode(opp.BillingStreet__c, 'UTF-8');
                
                req.setEndpoint(endpoint + query);
                req.setMethod('GET');
                req.setHeader('User-Agent', 'Salesforce Geocoding Service'); // Nominatim 필수
                req.setTimeout(10000); // 10초 타임아웃
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                System.debug('Nominatim API 응답 코드: ' + res.getStatusCode());
                System.debug('주소: ' + opp.BillingStreet__c);
                
                if (res.getStatusCode() == 200) {
                    // 응답 파싱
                    String responseBody = res.getBody();
                    List<Object> results = (List<Object>) JSON.deserializeUntyped(responseBody);
                    
                    if (results != null && !results.isEmpty()) {
                        Map<String, Object> firstResult = (Map<String, Object>) results[0];
                        
                        // 위도/경도 추출
                        Decimal latitude = Decimal.valueOf((String) firstResult.get('lat'));
                        Decimal longitude = Decimal.valueOf((String) firstResult.get('lon'));
                        
                        // Geolocation 필드 업데이트
                        opp.Location__Latitude__s = latitude;
                        opp.Location__Longitude__s = longitude;
                        opp.Geocoding_Status__c = '성공';
                        
                        oppsToUpdate.add(opp);
                        
                        System.debug('지오코딩 성공: ' + opp.BillingStreet__c + ' -> ' + latitude + ', ' + longitude);
                    } else {
                        // 결과 없음
                        opp.Geocoding_Status__c = '실패';
                        oppsToUpdate.add(opp);
                        System.debug('주소를 찾을 수 없습니다: ' + opp.BillingStreet__c);
                    }
                } else if (res.getStatusCode() == 429) {
                    // Rate limit 초과
                    opp.Geocoding_Status__c = '실패';
                    oppsToUpdate.add(opp);
                    System.debug('API 호출 제한 초과. 나중에 다시 시도하세요.');
                } else {
                    // 기타 오류
                    opp.Geocoding_Status__c = '실패';
                    oppsToUpdate.add(opp);
                    System.debug('API 호출 실패. 상태 코드: ' + res.getStatusCode());
                }
                
            } catch (Exception e) {
                opp.Geocoding_Status__c = '실패';
                oppsToUpdate.add(opp);
                System.debug('지오코딩 중 오류 발생: ' + e.getMessage());
            }
        }
        
        // 업데이트 실행
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
    
    // 단일 주소 지오코딩 (LWC에서 호출용)
    @AuraEnabled
    public static Map<String, Decimal> geocodeSingleAddress(String address) {
        if (String.isBlank(address)) {
            throw new AuraHandledException('주소가 없습니다.');
        }
        
        try {
            HttpRequest req = new HttpRequest();
            String endpoint = 'https://nominatim.openstreetmap.org/search';
            String query = '?format=json&limit=1&countrycodes=kr';
            query += '&q=' + EncodingUtil.urlEncode(address, 'UTF-8');
            
            req.setEndpoint(endpoint + query);
            req.setMethod('GET');
            req.setHeader('User-Agent', 'Salesforce Geocoding Service');
            req.setTimeout(10000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
                
                if (results != null && !results.isEmpty()) {
                    Map<String, Object> firstResult = (Map<String, Object>) results[0];
                    
                    Map<String, Decimal> coordinates = new Map<String, Decimal>();
                    coordinates.put('latitude', Decimal.valueOf((String) firstResult.get('lat')));
                    coordinates.put('longitude', Decimal.valueOf((String) firstResult.get('lon')));
                    
                    return coordinates;
                }
            }
            
            throw new AuraHandledException('주소를 찾을 수 없습니다.');
            
        } catch (Exception e) {
            throw new AuraHandledException('지오코딩 중 오류 발생: ' + e.getMessage());
        }
    }
}
