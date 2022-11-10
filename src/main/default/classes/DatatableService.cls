public with sharing class DatatableService {

    @AuraEnabled(cacheable=true)
    public static List<Column> callGetColumns(){
        Schema.FieldSet fieldSet = SObjectType.Account.FieldSets.SegmentViewerDynamic;

        return getColumnsForFieldSet(fieldSet);
    }

    public static List<Column> getColumnsForFieldSet(FieldSet fs) {
        List<Column> columns = new List<Column>();

        for(FieldSetMember fm : fs.getFields()) {
                Column c = new Column();
                    c.label = fm.getLabel();
                    c.fieldName = fm.getFieldPath();
                    c.sortable = true;

                    switch on fm.getType() {
                        when STRING {
                            c.type = 'text';
                        }
                        when DATE {
                            c.type = 'date';
                            c.typeAttributes = new TypeAttributes();
                            c.typeAttributes.year = 'numeric';
                            c.typeAttributes.month = '2-digit';
                            c.typeAttributes.day = '2-digit';
                        }
                        when CURRENCY {
                            c.type = 'currency';
                        }
                    }
                    columns.add(c);
            }

        return columns;
    }
    public class Column {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public Boolean sortable;
        @AuraEnabled
        public Integer initialWidth;
        @AuraEnabled
        public TypeAttributes typeAttributes;
        @AuraEnabled
        public CellAttributes cellAttributes;
    }

    public class TypeAttributes {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Object variant;
        @AuraEnabled
        public String iconName;
        @AuraEnabled
        public Object label;
        @AuraEnabled
        public String year;
        @AuraEnabled
        public String month;
        @AuraEnabled
        public String day;
        @AuraEnabled
        public String target;
        @AuraEnabled
        public CurrencyCode currencyCode;
    }

    public class CellAttributes {
        @AuraEnabled
        public String alignment;
    }

    public class TypeLabel {
        @AuraEnabled
        public String fieldName;
    }

    public class TypeVariant {
        @AuraEnabled
        public String fieldName;
    }

    public class CurrencyCode {
        @AuraEnabled
        public String fieldName;
    }
}