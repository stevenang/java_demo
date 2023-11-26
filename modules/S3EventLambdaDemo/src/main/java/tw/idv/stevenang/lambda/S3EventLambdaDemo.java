package tw.idv.stevenang.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.auth.credentials.EnvironmentVariableCredentialsProvider;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import tw.idv.stevenang.common.utils.S3Utils;

import java.net.URI;

@Slf4j
public class S3EventLambdaDemo implements RequestHandler<S3Event, Void> {

    private static final S3Client s3Client;

    static {
        S3Configuration s3Configuration = S3Configuration.builder().pathStyleAccessEnabled(true).build();
        s3Client = S3Client.builder()
                .credentialsProvider(EnvironmentVariableCredentialsProvider.create())
                .endpointOverride(URI.create("http://localhost.localstack.cloud:4566"))
                .serviceConfiguration(s3Configuration)
                .build();
    }

    @Override
    public Void handleRequest(S3Event s3Event, Context context) {
        log.info("Start processing s3 events...");
        s3Event.getRecords()
                .stream()
                .forEach(s3EventNotificationRecord -> {
                    log.info("Event Source : {}", s3EventNotificationRecord.getEventSource());
                    S3EventNotification.S3Entity entity = s3EventNotificationRecord.getS3();
                    log.info("Bucket Name : {}", entity.getBucket().getName());
                    log.info("Object Key : {}", entity.getObject().getKey());
                    log.info("Object: {} was created in {} bucket", entity.getObject().getKey(), entity.getBucket().getName());
                    String copyObjectResponse = S3Utils.copyBucketObject(s3Client, entity.getBucket().getName(), entity.getObject().getKey(), "test-bucket-03");
                    log.info("CopyObjectResponse: {}", copyObjectResponse);
                });
        return null;
    }
}
