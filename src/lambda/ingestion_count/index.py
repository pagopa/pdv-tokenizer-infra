import boto3, time, json, os, logging
from datetime import datetime,timedelta

athena = boto3.client('athena')
s3 = boto3.client('s3')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

database = os.environ['DATABASE']
output_bucket = os.environ['OUTPUT_BUCKET']
tokens_bucket = os.environ['TOKENS_BUCKET']
workgroup = os.environ['WORKGROUP']

def lambda_handler(event, context):
    # Load query template
    with open(os.path.join(os.path.dirname(__file__), 'query.sql'), 'r') as f:
        raw_query = f.read()

    query_string = raw_query.replace("{{db}}", database).replace("{{table}}", os.environ['TABLE_NAME'])

    
    prev_day = datetime.utcnow() - timedelta(days=1)
    year = prev_day.strftime("'%Y'")
    month = prev_day.strftime("'%m'")
    day = prev_day.strftime("'%d'")

    # Execution parameters for year, month, day
    execution_params = [year,month,day]

    # Start Athena query
    response = athena.start_query_execution(
        QueryString=query_string,
        QueryExecutionContext={'Database': database},
        ResultConfiguration={'OutputLocation': f"s3://{output_bucket}/"},
        ExecutionParameters=execution_params,
        WorkGroup= workgroup
    )

    query_id = response['QueryExecutionId']

    # Wait for completion
    while True:
        status = athena.get_query_execution(QueryExecutionId=query_id)['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(2)

    if status != 'SUCCEEDED':
        logger.error(f"Error  {response}")
        raise Exception(f"Athena query failed with status: {athena.get_query_execution(QueryExecutionId=query_id)}")
        
    # Get results
    results = athena.get_query_results(QueryExecutionId=query_id)
    rows = results['ResultSet']['Rows'][1:]  # Skip header

    for row in rows:
        namespace = row['Data'][0]['VarCharValue']
        count_value = int(row['Data'][4]['VarCharValue'])

        output_json = {
            "count": count_value,
            "date": f"{year}-{month}-{day}",
            "exportTimestamp": datetime.utcnow().isoformat()
        }

        # Store in S3 under results/{namespace}/result.json
        s3.put_object(
            Bucket=tokens_bucket,
            Key=f"tokens/{namespace}/count/{prev_day.strftime('%Y%m%d')}/{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json",
            Body=json.dumps(output_json),
            ContentType='application/json'
        )

    return {"status": "success", "message": "Results saved per namespace."}


#count/tenants/<yyyymmdd>/<yyyymmdd_hhmmss>.json

#{"count":8646,"exportTimestamp":"2025-07-15T06:47:24.237Z"}