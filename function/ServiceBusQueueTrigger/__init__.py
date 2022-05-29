import logging
import azure.functions as func
import psycopg2
import os
from datetime import datetime
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def main(msg: func.ServiceBusMessage):

    notification_id = int(msg.get_body().decode('utf-8'))
    logging.info('Python ServiceBus queue trigger processed message: %s',notification_id)

    # Get connection to database
    conn = psycopg2.connect(
        host=os.environ["POSTGRES_URL"],
        database=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PW"]
    )
    cur = conn.cursor()
    logging.info("Successfully connected to database.")

    try:
        # Get notification message and subject from database using the notification_id
        get_notification_query = f"SELECT message, subject FROM notification WHERE id={str(notification_id)}"
        cur.execute(get_notification_query)
        message, subject = cur.fetchone()
        logging.info(f"Notification ID {str(notification_id)} \n\t Subject: {subject} \n\t Message: {message}")
        
        # Get attendees email and name
        get_attendees_query = f"SELECT first_name, last_name, email FROM attendee;"
        cur.execute(get_attendees_query)
        attendees = cur.fetchall()

        # Loop through each attendee and send an email with a personalized subject
        for attendee in attendees:
            first_name=attendee[0]
            last_name=attendee[1]
            email=attendee[2]
            email_subject=f"Hello {first_name}! | {subject}"

            mail = Mail(
                from_email=os.environ['ADMIN_EMAIL_ADDRESS'],
                to_emails=email,
                subject=email_subject,
                plain_text_content=message
            )

            try:
                sg = SendGridAPIClient(os.environ['SENDGRID_API_KEY'])
                response = sg.send(mail)
                print(response.status_code)
                print(response.body)
                print(response.headers)
            except Exception as e:
                print(str(e))

        # Update the notification table by setting the completed date and updating the status with the total number of attendees notified
        completed_date = datetime.now()
        status = f"Notified {str(len(attendees))} attendees"
        
        notification_update_query=f"UPDATE notification SET status='{status}', completed_date='{completed_date}' WHERE id={notification_id};"
        cur.execute(notification_update_query)
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logging.error(error)
        conn.rollback()
    finally:
        # Close connection
        cur.close()
        conn.close()
        logging.info("PostgresSQL connection closed.")
