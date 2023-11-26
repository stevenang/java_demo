package tw.idv.stevenang.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.auth.credentials.EnvironmentVariableCredentialsProvider;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import tw.idv.stevenang.common.utils.S3Utils;

import java.net.URI;
import java.net.URISyntaxException;

@Slf4j
public class SqsEventLambdaDemo implements RequestHandler<SQSEvent, Void> {

    private static final ObjectMapper mapper;
    private static final S3Client s3Client;

    static {
        mapper = new ObjectMapper();
        S3Configuration s3Configuration = S3Configuration.builder().pathStyleAccessEnabled(true).build();
        s3Client = S3Client.builder()
                .credentialsProvider(EnvironmentVariableCredentialsProvider.create())
                .endpointOverride(URI.create("http://localhost.localstack.cloud:4566"))
                .serviceConfiguration(s3Configuration)
                .build();
    }

    @Override
    public Void handleRequest(SQSEvent sqsEvent, Context context) {
        log.info("Start processing sqs events...");
        sqsEvent.getRecords()
                .stream()
                .forEach(sqsMessage -> {
                    try {
                        // This will get the message main body from the SQS message
                        JsonNode recordNode = mapper.readTree(sqsMessage.getBody());
                        // The original message contains some characters which will causing error when parse to json. Need to clean the message first
                        String messageJson = recordNode.get("Message").asText().replace("\\", "").replace("\"\"", "\"");
                        // Parser the message into a json node
                        JsonNode messageNode = mapper.readTree(messageJson);
                        // Get records from the message node
                        messageNode.get("Records")
                                .elements()
                                .forEachRemaining(record -> {
                                    // Get s3 element from the record
                                    JsonNode s3 = record.get("s3");
                                    // Retrieve the bucket and object information
                                    JsonNode bucket = s3.get("bucket");
                                    JsonNode object = s3.get("object");
                                    log.info("Object: {} was created in {} bucket", object.get("key").asText(), bucket.get("name").asText());
                                    String copyObjectResponse = S3Utils.copyBucketObject(s3Client, bucket.get("name").asText(), object.get("key").asText(), "test-bucket-02");
                                    log.info("CopyObjectResponse: {}", copyObjectResponse);
                                });
                    } catch (JsonProcessingException e) {
                        throw new RuntimeException(e);
                    }
                });

        return null;
    }
}
