//
//  TGViewController.m
//  GearsGameCenter
//
//  Created by LJ-Jian on 2/22/2014.
//  Copyright (c) 2014 Gears. All rights reserved.
//

#import "TGViewController.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <MessageUI/MessageUI.h>

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <sys/types.h>
#include <net/if.h>
#include <netdb.h>

#include "util.h"

#import "TGAppDelegate.h"


@interface TGViewController () <MFMessageComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TGViewController

@synthesize webView = _webView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _webView.scalesPageToFit = YES;
    
    
	// Do any additional setup after loading the view, typically from a nib.
    
    //start web server
    
    NSString *ip = [Util getIPAddress];

    NSLog(@"ipaddress: %@", ip);

    NSString *gameName = @"Maze";
    
    NSString *fullURL = [[[[@"http://" stringByAppendingString:@"127.0.0.1" ] stringByAppendingString:@"/Games/"] stringByAppendingString:gameName] stringByAppendingString:@"/index.html"];
    
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:requestObj];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

- (IBAction)shareTapped:(id)sender {
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSString *gameName = @"Maze";
    
    NSString *gameLink = [[[[@"http://" stringByAppendingString:[Util getIPAddress]] stringByAppendingString:@"/Games/"] stringByAppendingString:gameName] stringByAppendingString:@"/index.html"];
    
    NSString *message = [@"Please join the Maze game: " stringByAppendingString:gameLink];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (IBAction)doneTapped:(id)sender {
    
    TGAppDelegate *delegate = (TGAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate.broadcasetingServer stop];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
