package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
)

func main() {
	// Load the Shared AWS Configuration (~/.aws/config)
	ctx := context.Background()
	queueName := "event-sqs-queue"
	endpoint := "http://localhost:4566"
	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithSharedConfigProfile("localstack"),
	)
	if err != nil {
		panic(fmt.Sprintf("failed loading config, %v", err))
	}

	fmt.Printf("queueName: %s endpoint: %s\n", queueName, endpoint)

	// Create an Amazon S3 service client
	client := sqs.NewFromConfig(cfg, func(o *sqs.Options) {
		o.BaseEndpoint = aws.String(endpoint)
	})

	queue, err := client.GetQueueUrl(ctx, &sqs.GetQueueUrlInput{QueueName: aws.String(queueName)})
	if err != nil {
		log.Fatal(err)
	}

	_, err = client.SendMessage(ctx, &sqs.SendMessageInput{
		MessageBody: aws.String("Hello from go, sqs!"),
		QueueUrl:    queue.QueueUrl,
	})

	if err != nil {
		log.Fatal(err)
	}

}
