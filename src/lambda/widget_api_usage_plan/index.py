import boto3
import json
from datetime import datetime, timedelta
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


apigw_client = boto3.client('apigateway')


def get_usage_plans():
    """Retrieve all usage plans from API Gateway."""
    usage_plans = []
    paginator = apigw_client.get_paginator('get_usage_plans')
    for page in paginator.paginate():
        usage_plans.extend(page['items'])
    return usage_plans


def get_usage_for_date(usage_plan_id, key_id, start_date, end_date):
    """Get usage for a specific date range"""
    response = apigw_client.get_usage(
        usagePlanId=usage_plan_id,
        keyId=key_id,
        startDate=start_date.strftime('%Y-%m-%d'),
        endDate=end_date.strftime('%Y-%m-%d')
    )
    return response.get('items', [])

def lambda_handler(event, context):
    # Parse widget context
    widget_context = event.get('widgetContext', {})
    
    # Get time range from widget context
    time_range = widget_context.get('timeRange', {})
    start_time = datetime.fromtimestamp(time_range.get('start', 0)/1000)
    end_time = datetime.fromtimestamp(time_range.get('end', 0)/1000)

    logger.info(f"Time range: {start_time} to {end_time}")
    
    # HTML template start with time range info
    html = f"""
    <div style="margin-bottom: 12px; font-family: Arial, sans-serif; color: #666;">
        Time Range: {start_time.strftime('%Y-%m-%d %H:%M')} to {end_time.strftime('%Y-%m-%d %H:%M')} UTC
    </div>
    <table style="width:100%; border-collapse: collapse; font-family: Arial, sans-serif;">
        <thead>
            <tr style="background-color: #f3f4f6;">
                <th style="padding: 12px; text-align: left; border-bottom: 2px solid #e5e7eb;">Plan Name</th>
                <th style="padding: 12px; text-align: left; border-bottom: 2px solid #e5e7eb;">API Key</th>
                <th style="padding: 12px; text-align: right; border-bottom: 2px solid #e5e7eb;">Usage</th>
                <th style="padding: 12px; text-align: right; border-bottom: 2px solid #e5e7eb;">Last Update</th>
            </tr>
        </thead>
        <tbody>
    """
    
    try:
        # Get all usage plans
        usage_plans = get_usage_plans()


        for plan in usage_plans:
            plan_id = plan['id']
            plan_name = plan['name']
            
            # Get keys for this plan
            keys = apigw_client.get_usage_plan_keys(usagePlanId=plan_id)

            #logger.info(f"Processing usage for plan: {plan_name}")
            
            for key in keys['items']:
                key_id = key['id']
                key_name = key['name']
                
                # Get usage data for the selected time range
                usage = get_usage_for_date(plan_id, key_id, start_time, end_time)

                # Process usage data
                total_usage = 0
                if not usage:
                    logger.debug(f"No usage data found for {plan_name} - {key_name}")
                   
                for day_data in usage:
                    total_usage = usage[day_data][0][0]
                
                # Add row to HTML
                html += f"""
                    <tr style="border-bottom: 1px solid #e5e7eb;">
                        <td style="padding: 12px;">{plan_name}</td>
                        <td style="padding: 12px;">{key_name}</td>
                        <td style="padding: 12px; text-align: right;">{total_usage:,}</td>
                        <td style="padding: 12px; text-align: right;">{end_time.strftime('%H:%M UTC')}</td>
                    </tr>
                """
        
        # Close HTML table
        html += """
        </tbody>
    </table>
    """
        
       # Return the response in the format expected by CloudWatch custom widgets
        return html
        
    except Exception as e:
        error_html = f"""
            <div style="color: #dc2626; padding: 16px; background-color: #fee2e2; border-radius: 4px;">
                Error loading API usage data: {str(e)}
            </div>
        """

        logger.error(f"Error loading API usage data: {str(e)}")
        return error_html
    


if __name__ == '__main__':
    # Simulate a widget event
    event = {
        'widgetContext': {
            'timeRange': {
                'start': 1630440000000,
                'end': 1630443600000
            }
        }
    }
    
    # Call the lambda handler
    result = lambda_handler(event, None)
    # Print the result
    print(result)