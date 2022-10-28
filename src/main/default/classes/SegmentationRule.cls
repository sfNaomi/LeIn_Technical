public with sharing class SegmentationRule {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String key;
    @AuraEnabled
    public String operator;
    @AuraEnabled 
    public String value;
    @AuraEnabled 
    public String type;
    
    private static String baseQuery = '(SELECT aforza__Account__c FROM aforza__Attribute_Assignment__c WHERE aforza__Attribute__r.Name =';
    private static Map<String,String> operatorMap = new Map<String,String>{
        'eq' => '=',
        'ne' => '!=',
        'gt' => '>',
        'ge' => '>=',
        'lt' => '<',
        'le' => '<='
    };

    @AuraEnabled(cacheable=true)
    public static List<SegmentationRule> parse(String json) {
        return (List<SegmentationRule>) System.JSON.deserialize(json, List<SegmentationRule>.class);
    }

    public String getQuery(){ 
        if (type == 'Toggle'){
            return getTypeToggle();
        } else {
            return getTypeDetail();
        }
    }

    public String getTypeToggle() {
        return ' Id' + (((operator == 'eq' && value=='true') || (operator == 'ne' && value=='false')) ? '' : ' NOT') + ' IN ' + baseQuery + '\''+ String.escapeSingleQuotes(name) + '\'' + ')';
    }
	
    public String getTypeDetail(){
        String query = ' Id IN ' + baseQuery + '\''+ String.escapeSingleQuotes(name) + '\'';
        String val = String.escapeSingleQuotes(value);
        
        if(operatorMap.containsKey(operator)) {
            if(val.isNumeric()) {
                query += ' AND Numeric_Value__c ' + operatorMap.get(operator) + ' ' + val + ')';
            }
            else {
                query += ' AND aforza__Value__c ' + operatorMap.get(operator) + ' \'' + val + '\')';
            }
        }
        else if (operator == 'cn'){
			query += ' AND aforza__Value__c LIKE ' +  '\'%'+ val + '%\'' + ')';
        } else if (operator == 'in'){
            query += ' AND aforza__Value__c IN' + '(' + '\'' + String.join(val.split(','), '\', \'') + '\'))';
        }
        return query;
    }
}