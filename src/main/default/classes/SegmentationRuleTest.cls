@isTest
private class SegmentationRuleTest {
    
    @isTest static void testParse(){
        String json = '[{\"name\":\"VIP\",\"key\":\"AA-0039\",\"operator\":\"eq\",\"value\":\"true\",\"type\":\"Toggle\"}]';
        List<SegmentationRule> listRules = new List<SegmentationRule>();
        SegmentationRule parsed = new SegmentationRule();
       	parsed.name = 'VIP';
        parsed.key = 'AA-0039';
        parsed.operator = 'eq';
        parsed.value = 'true';
        parsed.type = 'Toggle';
        listRules.add(parsed);
        System.assertEquals(listRules.toString(), SegmentationRule.parse(json).toString());
        
    }
	
    @isTest static void testToggle(){
        SegmentationRule toggle = new SegmentationRule();
        toggle.name = 'VIP';
        toggle.operator = 'eq';
        toggle.value = 'true';
        toggle.type = 'Toggle';
        
        String expectedResult = ' Id IN (SELECT aforza__Account__c'
            + ' FROM aforza__Attribute_Assignment__c'
            + ' WHERE aforza__Attribute__r.Name =' +'\''+ toggle.name + '\'' + ')';
        System.assertEquals(expectedResult, toggle.getQuery());
        
    }
    
    @isTest static void testDetail(){
        SegmentationRule detail = new SegmentationRule();
        detail.name = 'Point Of Sale Displays';
        detail.operator = 'cn';
        detail.value = '4';
        detail.type = 'Detail';
        String expectedResult = ' Id IN (SELECT aforza__Account__c'
            + ' FROM aforza__Attribute_Assignment__c'
            + ' WHERE aforza__Attribute__r.Name =' +'\''+ detail.name + '\'' 
            + ' AND aforza__Value__c LIKE ' +  '\'%'+ detail.value + '%\'' + ')';
        System.assertEquals(expectedResult, detail.getQuery());
    }
    
    @isTest static void testNumericValue(){
        SegmentationRule detail = new SegmentationRule();
        detail.name = 'Point Of Sale Displays';
        detail.operator = 'ne';
        detail.value = '4';
        detail.type = 'Detail';
        String expectedResult = ' Id IN (SELECT aforza__Account__c'
            + ' FROM aforza__Attribute_Assignment__c'
            + ' WHERE aforza__Attribute__r.Name =' +'\''+ detail.name + '\'' 
            + ' AND Numeric_Value__c != ' + detail.value + ')';
        System.assertEquals(expectedResult, detail.getQuery());
    }
    
    @isTest static void testRating(){
        SegmentationRule rating = new SegmentationRule();
        rating.name = 'Point Of Sale Displays';
        rating.operator = 'in';
        rating.value = '5';
        rating.type = 'Rating';
        String expectedResult = ' Id IN (SELECT aforza__Account__c'
            + ' FROM aforza__Attribute_Assignment__c'
            + ' WHERE aforza__Attribute__r.Name =' +'\''+ rating.name + '\'' 
            + ' AND aforza__Value__c IN(' + '\'' + String.join(rating.value.split(','), '\', \'') + '\'))';
        System.assertEquals(expectedResult, rating.getQuery());
    }
    
    @isTest static void testSentiment(){
        SegmentationRule sentiment = new SegmentationRule();
        sentiment.name = 'Cold Calls';
        sentiment.operator = 'ne';
        sentiment.value = 'neutral';
        sentiment.type = 'Sentiment';
        String expectedResult = ' Id IN (SELECT aforza__Account__c'
            + ' FROM aforza__Attribute_Assignment__c'
            + ' WHERE aforza__Attribute__r.Name =' +'\''+ sentiment.name + '\'' 
            + ' AND aforza__Value__c != ' + '\''+ sentiment.value + '\''+ ')';
        System.assertEquals(expectedResult, sentiment.getQuery());
    }
}