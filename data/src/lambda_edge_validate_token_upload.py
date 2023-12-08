from urllib.parse import urlencode, quote
import http.cookies as cookies
import http.client 
import base64
import boto3
from botocore.exceptions import *
import json
import os 

def retrieve_credentials() :
    s3_client = boto3.client("s3")
    response = s3_client.get_object(Bucket = "styl-file-upload-download-bucket", Key = "data_serve_lambda_edge.json")

    return response['Body'].read().decode("utf-8")

def set_env_variables(data) :
    print(data)
    data = json.loads(data)
    
    os.environ['CLIENT_ID']              = data['cognito_user_pool_client_id']['value']
    os.environ['CLIENT_SECRET']          = data['cognito_user_pool_client_secret']['value']

    print(data['cognito_user_pool_domain_url']['value'])
    
    os.environ['USER_POOL_ID']           = data['cognito_user_pool_id']['value']
    # os.environ['USER_POOL_DOMAIN_URL']   = "stylcoggooglev2" + data['cognito_user_pool_domain_url']['value']
    os.environ['USER_POOL_DOMAIN_URL']   =  data['cognito_user_pool_domain_url']['value']
    os.environ['COGNITO_IDP']            = "cognito-idp.ap-southeast-1.amazonaws.com"

    os.environ['CLOUDFRONT_DOMAIN']      = data['cloudfront_upload_domain_name']['value']
    

def read_data() :
    file_path = os.path.join(f"/tmp", "data_serve_lambda_edge.json")
    while (True) :
        try :
            with open(file_path, "r") as file : 
                data = file.read()            
            
            print("READ TEMPORARY CREDETIALS")
            set_env_variables(data)
            break
        
        except :
            print("RETRIEVE CREDENTIALS FROM S3")
            with open(file_path, "w") as file : 
                file.write(retrieve_credentials())  

def encode_base64(A, B) :
    if (B == "") : credentials = A
    else : credentials = f"{A}:{B}"
    
    credentials_bytes = credentials.encode('utf-8')
    return  base64.b64encode(credentials_bytes).decode('utf-8')

def decode_base64(encode_token) :
    encode_token = encode_token.encode('utf-8')
    return base64.b64decode(encode_token).decode('utf-8')

def exchange_code_for_token(request) : 
    CLIENT_ID               = os.getenv('CLIENT_ID')
    CLIENT_SECRET           = os.getenv('CLIENT_SECRET')
    CLOUDFRONT_DOMAIN       = os.getenv('CLOUDFRONT_DOMAIN')
    USER_POOL_DOMAIN_URL    = os.getenv('USER_POOL_DOMAIN_URL')

    credentials_base64 = encode_base64(CLIENT_ID, CLIENT_SECRET)

    headers = {
        'content-type': 'application/x-www-form-urlencoded',
        'authorization': 'Basic ' + credentials_base64
    }


    code = request['querystring'].split("=")[1]
    data = {
        'grant_type': 'authorization_code',
        'redirect_uri': f'https://{CLOUDFRONT_DOMAIN}/auth',
        'code': code
    }

    final_response = {
        'status': '302',
        'statusDescription': 'Found',
        'headers': {
            'location': [{
                'key': 'Location',
                'value': '/'
            }]
        }
    }    

    conn = http.client.HTTPSConnection(USER_POOL_DOMAIN_URL)
    conn.request("POST", "/oauth2/token", urlencode(data), headers)

    response = conn.getresponse()
    response_data = eval(response.read().decode('utf-8'))
    
    print("RESPONSE_DATA OF TOKENS : ", response_data)

    if ('error' in response_data) : 
        final_response['headers']['location'][0]['value'] = '/unauthorize'

    else :
        my_cookie = cookies.SimpleCookie()
        my_cookie['token'] = response_data['access_token']
        my_cookie['token']['max-age'] = response_data['expires_in']
        my_cookie['token']['secure'] = True
        my_cookie['token']['path'] = '/'
        
        cookie_value = my_cookie.output(header = '')
        print("MY COOKIE VALUE RETRIEVE FROM /oauth2/token ENDPOINT : ", cookie_value)
        final_response['headers']['location'][0]['value'] = '/upload.html'
        
        final_response['headers']['set-cookie'] = [{
            'key': 'Set-Cookie',
            'value' : cookie_value
        }]

        final_response['headers']['cache-control'] = [{ 
            'key': 'Cache-Control',
            'value': 'no-cache'
        }]

    print("SET COOKIES SUCCESS, RETURN RESPONSE WITH COOKIE ", final_response)
    return final_response

# ------------------------------- VALIDATION METHOD ------------------------------- #

def verify_jwt_token(access_token, request) :
    USER_POOL_ID = os.getenv('USER_POOL_ID')
    try : 
        client = boto3.client("cognito-idp", region_name = "ap-southeast-1")
        response = client.get_user(AccessToken = access_token)
        email_info = response['UserAttributes'][6]['Value']
        user_name = response['Username']

        print(email_info, '\t', user_name)
        if ("styl.solutions" not in email_info)  : 
            client.admin_disable_user(
                UserPoolId = USER_POOL_ID,
                Username = user_name
            )

            print("email disable : ", email_info)
            return (-1, "UNAUTHORIZE USERS")
            
        elif (request['uri'].startswith('/api')) : return (-1, "UNAUTHORIZE USERS")
    
        return (1, "USER VERIFIED") 
        
        
    except Exception as error : 
        status_code = -2
        print(error)
        if ("User is disabled" in str(error)) : status_code = -1
        return (status_code, error)

def lambda_handler(event, context) :
    read_data()
    CLIENT_ID               = os.getenv('CLIENT_ID')
    CLOUDFRONT_DOMAIN       = os.getenv('CLOUDFRONT_DOMAIN')
    
    print("EVENT FROM CLOUDFRONT : ", event)
    
    request = event['Records'][0]['cf']['request']

    if (request['uri'].startswith('/auth')) :
        return exchange_code_for_token(request)

    access_token = None
    status_code = -2
    message = "NO COOKIE FOUND"

    if 'cookie' in request['headers'] : 
        
        access_token = request['headers']['cookie'][0]['value'].split("=")[1]
        print("ACCESS_TOKEN : ", access_token)
        status_code, message    = verify_jwt_token(access_token, request)

        
    if (access_token == None or status_code == -2) :
        if (status_code == -2) : print("ERROR VERIFY USER", message)
        print("FAIL VALIDATION, UNAUTHORIZE ACCESS !!!! REDIRECT TO SIGN-IN PAGE.")
        
        redirect_uri = quote(f"https://{CLOUDFRONT_DOMAIN}/auth", safe = "")
        redirect_response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': f'https://styl-filesharing.auth.ap-southeast-1.amazoncognito.com/oauth2/authorize?client_id={CLIENT_ID}&response_type=code&scope=aws.cognito.signin.user.admin+email+openid+profile&redirect_uri={redirect_uri}' 
                    
                }]
            }
        }

        print("REDIRECT RESPONSE TO COGNITO SIGN-IN : ", redirect_response)
        return redirect_response
    
    if (status_code == -1) :
        print("ERROR VERIFY USER : ", message)
        
        my_cookie = cookies.SimpleCookie()
        my_cookie['token'] = ""
        my_cookie['token']['expires'] = 'Thu, 01 Jan 1970 00:00:00 GMT'
        my_cookie['token']['secure'] = True
        my_cookie['token']['path'] = '/'
        cookie_value = my_cookie.output(header = '')
        
        unauthorize_response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': '/unauthorize'
                }],
                
                'set-cookie' : [{
                    'key': 'Set-Cookie',
                    'value' : cookie_value
                }] 
            }
        }

        print("UNAUTHORIZE ACCESS : ", unauthorize_response)
        return unauthorize_response
    
    else : 
        print("SUCCESSFUL VALIDATION : ", request)
        return request
