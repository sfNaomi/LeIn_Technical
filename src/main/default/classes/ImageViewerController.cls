public with sharing class ImageViewerController {
    @AuraEnabled
    public static GenericObjectDTO getImageFiles(String selectType, String selectStatus, String selectObject, String selectAccount, Date selectStart, Date selectEnd){
        List<GenericObjectDataDTO> genericObjectDataDtoList = new List<GenericObjectDataDTO>();
        List<GenericObjectDTO> genericObjectDTOList = new List<GenericObjectDTO>();
        
        String queryString = '';
        
        /*
         * Query for Audit Assets
         */
        Map<Id, aforza__Audit_Asset__c> auditAssets = new Map<Id, aforza__Audit_Asset__c>();
        if (selectObject == null || selectObject == '' || selectObject == 'Audit Asset') {
            queryString = 'SELECT Id, CreatedBy.Id, createdBy.Name, CreatedDate, aforza__Audit__r.aforza__Account__c, aforza__Audit__r.aforza__Account__r.Name, aforza__Audit__c, aforza__Audit__r.aforza__Type__c, aforza__Audit__r.Name, aforza__Audit__r.aforza__Status__c FROM aforza__Audit_Asset__c ';
            queryString = queryFilters(true, queryString, selectType, selectStatus, selectObject, selectAccount, selectStart, selectEnd);
            auditAssets = new Map<Id, aforza__Audit_Asset__c>((List<aforza__Audit_Asset__c>)database.query(queryString));
        }


        /*
         * Query for Audits
         */
        Map<Id, aforza__Audit__c> audits = new Map<Id, aforza__Audit__c>();
        if (selectObject == null || selectObject == '' || selectObject == 'Audit') {
            queryString = 'SELECT Id, CreatedBy.Id, createdBy.Name, CreatedDate, aforza__Account__c, aforza__Account__r.Name, aforza__Type__c, Name, aforza__Status__c FROM aforza__Audit__c ';
            queryString = queryFilters(false, queryString, selectType, selectStatus, selectObject, selectAccount, selectStart, selectEnd);
            audits = new Map<Id, aforza__Audit__c>((List<aforza__Audit__c>)database.query(queryString));
        }

        /*
         * Query for Visits
         */
        Map<Id, aforza__Visit__c> visits = new Map<Id, aforza__Visit__c>();
        if (selectObject == null || selectObject == '' || selectObject == 'Visit') {
            queryString = 'SELECT Id, CreatedBy.Id, createdBy.Name, CreatedDate, aforza__Account__c, aforza__Account__r.Name, aforza__Type__c, Name, aforza__Status__c FROM aforza__Visit__c ';
            queryString = queryFilters(false, queryString, selectType, selectStatus, selectObject, selectAccount, selectStart, selectEnd);
            visits = new Map<Id, aforza__Visit__c>((List<aforza__Visit__c>)database.query(queryString));
        }
	
        
        List<Id> mergedIds = new List<Id>();
        mergedIds.addAll(auditAssets.keySet());
        mergedIds.addAll(audits.keySet());
        mergedIds.addAll(visits.keySet());
        
        /*
         * QUERY for files
         */
        if( (auditAssets != null && !auditAssets.keySet().isEmpty()) || (audits != null && !audits.keySet().isEmpty()) || (visits != null && !visits.keySet().isEmpty()) ){
            
            Set<Id> splitIds = new Set<Id>();
            List<ContentDocumentLink> queryResult = new List<ContentDocumentLink>();

            if (mergedIds.size() >= 2000) {
                for (Integer i = mergedIds.size() - 1; i >= 0; i--) {
                    if (math.mod(i, 2000) == 0 && splitIds.size() > 0) {
                        List<ContentDocumentLink> tempQuery = [SELECT id, ContentDocumentId, LinkedEntityId, ContentDocument.Title,
                                                            ContentDocument.LatestPublishedVersionId, SystemModstamp FROM  ContentDocumentLink 
                                                            WHERE (LinkedEntityId IN :splitIds)
                                                            AND ContentDocument.FileType != 'SNOTE'];
                        
                        queryResult.addAll(tempQuery);
                        splitIds.clear();
                    } else {
                        splitIds.add(mergedIds[i]);
                        mergedIds.remove(i);
                    }
                }
            }

            List<ContentDocumentLink> tempQuery = [SELECT id, ContentDocumentId, LinkedEntityId, ContentDocument.Title,
                                                        ContentDocument.LatestPublishedVersionId, SystemModstamp FROM  ContentDocumentLink 
                                                        WHERE (LinkedEntityId IN :mergedIds)
                                                        AND ContentDocument.FileType != 'SNOTE'];
                    
            queryResult.addAll(tempQuery);

            
            /*
            List<ContentDocumentLink> queryResult = [SELECT id, ContentDocumentId, LinkedEntityId, ContentDocument.Title,
                                                        ContentDocument.LatestPublishedVersionId, SystemModstamp FROM  ContentDocumentLink 
                                                        WHERE (LinkedEntityId IN : auditAssets.keySet()
                                                        OR LinkedEntityId IN : audits.keySet()
                                                        OR LinkedEntityId IN : visits.keySet())
                                                        AND ContentDocument.FileType != 'SNOTE'];
			*/

            /*
             * Add details to queried files
             */
            GenericObjectDTO genericDtoObj = new GenericObjectDTO();
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
            String contentUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=';
            Boolean found = false;
            for(ContentDocumentLink obj :queryResult){
                GenericObjectDataDTO  genericObj = New GenericObjectDataDTO();
                if(auditAssets.containsKey(obj.LinkedEntityId) || audits.containsKey(obj.LinkedEntityId) || visits.containsKey(obj.LinkedEntityId)) {
                    genericObj.url = baseUrl;
                    genericObj.createdDate = string.valueOf(obj.SystemModstamp);
                    genericObj.fileRecord = obj.ContentDocument.Title;
                    genericObj.latestVersionId = obj.ContentDocument.LatestPublishedVersionId;
                    genericObj.fileId = obj.ContentDocumentId;
                    genericObj.fileSrc = baseUrl + contentUrl + obj.ContentDocument.LatestPublishedVersionId;
                    found = true;
                }

                if(auditAssets.containsKey(obj.LinkedEntityId)){
                    genericObj.recordName =  auditAssets.get(obj.LinkedEntityId).aforza__Audit__r.Name;
                    genericObj.accountId = auditAssets.get(obj.LinkedEntityId).aforza__Audit__r.aforza__Account__c;
                    genericObj.accountName = auditAssets.get(obj.LinkedEntityId).aforza__Audit__r.aforza__Account__r.Name;
                    genericObj.createdBy = auditAssets.get(obj.LinkedEntityId).CreatedById;
                    genericObj.status = auditAssets.get(obj.LinkedEntityId).aforza__Audit__r.aforza__Status__c;
                    genericObj.type = auditAssets.get(obj.LinkedEntityId).aforza__Audit__r.aforza__Type__c;
                    genericObj.objectType = 'Audit Asset';
                    genericObj.Id = auditAssets.get(obj.LinkedEntityId).Id;
                    genericObj.createdByName = auditAssets.get(obj.LinkedEntityId).createdBy.Name;                    
                } else if (audits.containsKey(obj.LinkedEntityId)) {
                    genericObj.recordName =  audits.get(obj.LinkedEntityId).Name;
                    genericObj.accountId = audits.get(obj.LinkedEntityId).aforza__Account__c;
                    genericObj.accountName = audits.get(obj.LinkedEntityId).aforza__Account__r.Name;
                    genericObj.createdBy = audits.get(obj.LinkedEntityId).CreatedById;
                    genericObj.status = audits.get(obj.LinkedEntityId).aforza__Status__c;
                    genericObj.type = audits.get(obj.LinkedEntityId).aforza__Type__c;
                    genericObj.objectType = 'Audit';
                    genericObj.createdDate = string.valueOf(obj.SystemModstamp);
                    genericObj.Id = audits.get(obj.LinkedEntityId).Id;
                    genericObj.createdByName = audits.get(obj.LinkedEntityId).createdBy.Name;
                } else if (visits.containsKey(obj.LinkedEntityId)) {
                    genericObj.recordName =  visits.get(obj.LinkedEntityId).Name;
                    genericObj.accountId = visits.get(obj.LinkedEntityId).aforza__Account__c;
                    genericObj.accountName = visits.get(obj.LinkedEntityId).aforza__Account__r.Name;
                    genericObj.createdBy = visits.get(obj.LinkedEntityId).CreatedById;
                    genericObj.status = visits.get(obj.LinkedEntityId).aforza__Status__c;
                    genericObj.type = visits.get(obj.LinkedEntityId).aforza__Type__c;
                    genericObj.objectType = 'Visit';
                    genericObj.Id = visits.get(obj.LinkedEntityId).Id;
                    genericObj.createdByName = visits.get(obj.LinkedEntityId).createdBy.Name;
                }

                if (found) {
                    genericObjectDataDtoList.add(genericObj);
                }
                found = false;

                if(!genericObjectDataDtoList.isEmpty()){
                    genericDtoObj.genericDto = genericObjectDataDtoList;
                }  
            }
            genericObjectDTOList.add(genericDtoObj);
            return genericDtoObj;
        }
        return null;
    }
    
    public static String queryFilters(Boolean asset, String queryString, String selectType, String selectStatus, String selectObject, String selectAccount, Date selectStart, Date selectEnd) {
        if(String.isNotEmpty(selectType) || String.isNotEmpty(selectStatus) || String.isNotEmpty(selectAccount) || !(selectStart==null) || !(selectEnd==null)){
            queryString += ' WHERE ';
        }
        if(String.isNotEmpty(selectAccount)){
            queryString += asset == true ? ' aforza__Audit__r.aforza__Account__c = :selectAccount AND ' : ' aforza__Account__c = :selectAccount AND ';
        }
        if(String.isNotEmpty(selectType)){
            queryString += asset == true ? ' aforza__Audit__r.aforza__Type__c = :selectType AND ' : 'aforza__Type__c = :selectType AND ';
        }
        if(String.isNotEmpty(selectStatus)){
            queryString += asset == true ? ' aforza__Audit__r.aforza__Status__c = :selectStatus AND ' : 'aforza__Status__c = :selectStatus AND ';
        }
        if(selectStart != null){
            queryString += 'CreatedDate >= :selectStart AND ';
        }
        if(selectEnd != null){
            queryString += 'CreatedDate <= :selectEnd AND ';
        }
        queryString = queryString.trim();
        if( queryString.endsWith(' AND')){
            queryString = queryString.removeEnd( ' AND');
        }

        return queryString;
    }

    public class GenericObjectDataDTO{
        @AuraEnabled public String url;
        @AuraEnabled public String Id;
        @AuraEnabled public String latestVersionId;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String recordName;
        @AuraEnabled public String status;
        @AuraEnabled public String fileRecord;
        @AuraEnabled public String type;
        @AuraEnabled public String objectType;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String createdBy;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String fileId;
        @AuraEnabled public String fileSrc;
    }
     
    public class GenericObjectDTO{
        @AuraEnabled public List<GenericObjectDataDTO> genericDto;
    }
}