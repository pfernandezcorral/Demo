/**
 * Custom component controller class. This class generates lightning like related lists by using given attributes.
 * @author Mert YALTI
 * @date 26.06.2017
 */
public with sharing class LightningReadyRelatedListController {
	public sObject[] objectList {get; set;}
	public Integer initialSize {get; set;}
	public String fSetName {get; set;}
	public String objectAPI {get; set;}
	public String parentAPI {get; set;}
	public String relName {get; set;}
	public String pId {get; set;}
	Map<String, Schema.SObjectType> globalDescribeMap {get; set;}
	public LightningReadyRelatedListController() {
		objectList = new List<sObject>();
		globalDescribeMap = Schema.getGlobalDescribe();
	}

	/**
	 * Finds and returns the field set by using field set name attribute
	 * @return List<Schema.FieldSetMember>
	 */
	public List<Schema.FieldSetMember> fieldSet {
		get{
			if (!String.isBlank(objectName)) {

				if (!String.isBlank(fSetName)) {
					fSetName = !fSetName.startsWith(Settings.ns) ?  Settings.ns+fSetName :fSetName;
					Schema.SObjectType SObjectTypeObj = globalDescribeMap.get(objectName);
					Schema.DescribeSObjectResult describeSObjectResultObj = SObjectTypeObj.getDescribe();
					Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fSetName);
					return fieldSetObj.getFields();
				}
				return null;
			}
			return null;
		}
	}
	public String getNameSpace(){
		return Settings.ns;
	}
	String SOQL_STRING = 'SELECT Id, (SELECT {0} FROM {1}) FROM {2} WHERE Id =: pId';
	public List<sObject> getdataset() {
		if (dataList == null || Test.isRunningTest()) {
			dataList = new List<sObject>();
			relName = !relName.startsWith(Settings.ns) && relName.endsWith('__r') ? Settings.ns+relName : relName;
			parentAPI = !parentAPI.startsWith(Settings.ns) && parentAPI.endsWith('__c') ?  Settings.ns+parentAPI : parentAPI;
			Map<String, String> fields = Utilities.getAllFields(objectAPI);
			if (fields != null && fields.containsKey(Label.FIELDS)) {
				String soql = String.format(SOQL_STRING, new String[] {fields.get(Label.FIELDS), relName, parentAPI});
				

				for (sObject ps : database.query(soql)) {
					dataList.addAll((List<sObject>)ps.getSObjects(relName));
				}
				objectPrefix = dataList[0].getSObjectType().getDescribe().getKeyPrefix();
				objectName = dataList[0].getSObjectType().getDescribe().getName();
				objectLabel = dataList[0].getSObjectType().getDescribe().getLabel();
			}

			return dataList;
		}
		return dataList;
	}
	public List<sObject> dataList {
		get{
			if (objectList != null && !objectList.isEmpty()) {
				dataList = objectList;
			} else {
				relName = !relName.startsWith(Settings.ns) && relName.endsWith('__r') ? Settings.ns+relName : relName;
				parentAPI = !parentAPI.startsWith(Settings.ns) && parentAPI.endsWith('__c') ?  Settings.ns+parentAPI : parentAPI;
				if (dataList == null) {
					dataList = new List<sObject>();
					Map<String, String> fields = Utilities.getAllFields(objectAPI);
					if (fields != null && fields.containsKey(Label.FIELDS)) {
						String soql = String.format(SOQL_STRING, new String[] {fields.get(Label.FIELDS), relName, parentAPI});
						
						for (sObject ps : database.query(soql)) {
							List<sObject> relatedSobjects = (List<sObject>)ps.getSObjects(relName);
							System.debug(relatedSobjects);
							if(relatedSobjects!=null)
								dataList.addAll(relatedSObjects);
						}
						if( dataList.size()>0 ) {
							objectPrefix = dataList[0].getSObjectType().getDescribe().getKeyPrefix();
							objectName = dataList[0].getSObjectType().getDescribe().getName();
							objectLabel = dataList[0].getSObjectType().getDescribe().getLabel();
						}
					}
				}
			}
			return dataList;
		}
		set;
	}
	public String getViewAllURL() {
		relName = !relName.startsWith(Settings.ns) && relName.endsWith('__r') ? Settings.ns+relName : relName;
		return '/' + objectPrefix + '?rlapiid=' + relName + '&Id=' + pId;
	}
	/**
	 * Finds and returns sObject's API NAME.
	 * In the component this is being passed as a attribute
	 * @return String sObject api name
	 */
	public String objectName {
		get {
			if (objectList != null && !objectList.isEmpty())
				return objectList[0].getSObjectType().getDescribe().getName();
			else if (String.isBlank(objectName))
				return '';
			else {
				return objectName;
			}
		}
		set;
	}

	/**
	 * Finds and returns sObject's prefix.
	 * In the component this is being passed as a attribute
	 * @return String sObject prefix
	 */
	public String objectPrefix {
		get {
			if (objectList != null && !objectList.isEmpty())
				return objectList[0].getSObjectType().getDescribe().getKeyPrefix();
			else if (String.isBlank(objectPrefix))
				return '';
			else {
				return objectPrefix;
			}
		}
		set;
	}

	/**
	 * Finds and returns sObject's Label.
	 * In the component sObject is being passed as a attribute
	 * @return String sObject label
	 */
	public String objectLabel {
		get {
			if (objectList != null && !objectList.isEmpty())
				return objectList[0].getSObjectType().getDescribe().getLabel();
			else if (String.isBlank(objectLabel))
				return '';
			else {
				return objectLabel;
			}
		}
		set;
	}
}