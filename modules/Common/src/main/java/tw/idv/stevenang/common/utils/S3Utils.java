package tw.idv.stevenang.common.utils;

import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CopyObjectRequest;
import software.amazon.awssdk.services.s3.model.CopyObjectResponse;
import software.amazon.awssdk.services.s3.model.S3Exception;

@Slf4j
public class S3Utils {

    public static String copyBucketObject(S3Client s3Client, String sourceBucket, String objectKey, String destinationBucket)
            throws S3Exception {

        log.info("Copy {} from {} to {}", objectKey, sourceBucket, destinationBucket);

        CopyObjectRequest copyObjectRequest = CopyObjectRequest.builder()
                .sourceBucket(sourceBucket)
                .sourceKey(objectKey)
                .destinationBucket(destinationBucket)
                .destinationKey(objectKey)
                .build();

        CopyObjectResponse copyObjectResponse = s3Client.copyObject(copyObjectRequest);

        return copyObjectResponse.copyObjectResult().toString();
    }
}
