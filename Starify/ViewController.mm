//
//  ViewController.m
//  Starify
//
//  Created by ChaunceyLu on 3/9/15.
//  Copyright (c) 2015 ChaunceyLu. All rights reserved.
//
#import <Availability.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#endif
#import "ViewController.h"
#import "MBProgressHUD.h"
@interface ViewController ()

@end

@implementation ViewController {
    UIButton *pickFromLib, *takePhoto, *retake, *compare;
    UIImagePickerController *imagePicker;
    CGSize screenSize;
    UIImageView *imageView, *originView;
    UISlider *slider;
    cv::Mat I1;
    std::vector<cv::Point2f> inputpoint;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    screenSize = [[UIScreen mainScreen] bounds].size;
    int heightOffset40 = (double)40 / 568 * screenSize.height;
    int heightOffset280 = (double)280 / 568 * screenSize.height;
    int heightOffset320 = (double)320 / 568 * screenSize.height;
    NSString *API_KEY = @"a5be9907f9aff665d502fa003d8128b9", *API_SECRET = @"0QB5uV-A_XjxzwTf-Z9KHqpGdZlNlxAd";
    imagePicker = [[UIImagePickerController alloc] init];
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.width / 360 * 480)];
    originView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.width / 360 * 480)];
    pickFromLib = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    takePhoto = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    retake = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    compare = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    slider = [[UISlider alloc] init];
    slider.frame = CGRectMake(0.0, 480, screenSize.width, heightOffset40);
    [pickFromLib setTitle:@"从相册里选择" forState:UIControlStateNormal];
    [takePhoto setTitle:@"拍照" forState:UIControlStateNormal];
    [retake setTitle:@"重新选择" forState:UIControlStateNormal];
    [compare setTitle:@"对比原图" forState:UIControlStateNormal];
    [slider addTarget:self action:@selector(sliderValueChanged) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    pickFromLib.frame = CGRectMake(screenSize.width / 3, heightOffset280, screenSize.width / 3, heightOffset40);
    takePhoto.frame = CGRectMake(screenSize.width / 3, heightOffset320, screenSize.width / 3, heightOffset40);
    retake.frame = CGRectMake(0.0, screenSize.height - heightOffset40, screenSize.width / 2, heightOffset40);
    compare.frame = CGRectMake(screenSize.width / 2, screenSize.height - heightOffset40, screenSize.width / 2, heightOffset40);
    [self.view addSubview:pickFromLib];
    [self.view addSubview:takePhoto];
    [self.view addSubview:imageView];
    [self.view addSubview:slider];
    [self.view addSubview:retake];
    [self.view addSubview:compare];
    [self.view addSubview:originView];
    slider.hidden = YES;
    retake.hidden = YES;
    originView.hidden = YES;
    compare.hidden = YES;
    [pickFromLib addTarget:self
                    action:@selector(pickFromLibraryButtonPressed)
          forControlEvents:UIControlEventTouchUpInside];
    [takePhoto addTarget:self
                  action:@selector(pickFromCameraButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];
    [retake addTarget:self
               action:@selector(retakeButtonClicked)
     forControlEvents:UIControlEventTouchUpInside];
    [compare addTarget:self
                action:@selector(compareButtonUp)
      forControlEvents:UIControlEventTouchUpInside];
    [compare addTarget:self
                action:@selector(compareButtonDown)
      forControlEvents:UIControlEventTouchDown];
    [FaceppAPI initWithApiKey:API_KEY andApiSecret:API_SECRET andRegion:APIServerRegionCN];
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)pickFromCameraButtonPressed {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"出错啦"
                              message:@"读取摄像头失败"
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
}
-(void)retakeButtonClicked{
    imageView.hidden = YES;
    slider.hidden = YES;
    retake.hidden = YES;
    compare.hidden = YES;
}
-(void)pickFromLibraryButtonPressed {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"出错啦"
                              message:@"读取相册失败"
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
}
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    UIImage *sourceImage = info[UIImagePickerControllerOriginalImage];
    UIImage *imageToDisplay = [self fixOrientation:sourceImage];
    
    // perform detection in background thread
    [self performSelectorInBackground:@selector(detectWithImage:) withObject:imageToDisplay];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
-(void) detectWithImage: (UIImage*) image {
    FaceppResult *detectResult = [[FaceppAPI detection] detectWithURL:nil orImageData:UIImageJPEGRepresentation(image, 0.5) mode:FaceppDetectionModeNormal attribute:FaceppDetectionAttributeGender];
    if (detectResult.success) {
        int face_count = (int)[[detectResult content][@"face"] count];
        if (face_count > 1) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"出错啦"
                                  message:@"镜头里太多脸，我都分不出来了！"
                                  delegate:nil
                                  cancelButtonTitle:@"OK!"
                                  otherButtonTitles:nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        }
        else if (face_count == 0) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"出错啦"
                                  message:@"没在镜头里看到脸喔！"
                                  delegate:nil
                                  cancelButtonTitle:@"OK!"
                                  otherButtonTitles:nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        }
        else {
            NSArray *landmarkKeys = [[NSArray alloc] initWithObjects:@"contour_chin",@"contour_left1",@"contour_left2",@"contour_left3",@"contour_left4",@"contour_left5",@"contour_left6",@"contour_left7",
                                     @"contour_left8",@"contour_left9",@"contour_right1",@"contour_right2",@"contour_right3",@"contour_right4",@"contour_right5",@"contour_right6",
                                     @"contour_right7",@"contour_right8",@"contour_right9",@"left_eye_bottom",@"left_eye_center",@"left_eye_left_corner",@"left_eye_lower_left_quarter",
                                     @"left_eye_lower_right_quarter",@"left_eye_pupil",@"left_eye_right_corner",@"left_eye_top",@"left_eye_upper_left_quarter",@"left_eye_upper_right_quarter",
                                     @"left_eyebrow_left_corner",@"left_eyebrow_lower_left_quarter",@"left_eyebrow_lower_middle",@"left_eyebrow_lower_right_quarter",
                                     @"left_eyebrow_right_corner",@"left_eyebrow_upper_left_quarter",@"left_eyebrow_upper_middle",@"left_eyebrow_upper_right_quarter",@"mouth_left_corner",
                                     @"mouth_lower_lip_bottom",@"mouth_lower_lip_left_contour1",@"mouth_lower_lip_left_contour2",@"mouth_lower_lip_left_contour3",@"mouth_lower_lip_right_contour1",
                                     @"mouth_lower_lip_right_contour2",@"mouth_lower_lip_right_contour3",@"mouth_lower_lip_top",@"mouth_right_corner",@"mouth_upper_lip_bottom",
                                     @"mouth_upper_lip_left_contour1",@"mouth_upper_lip_left_contour2",@"mouth_upper_lip_left_contour3",@"mouth_upper_lip_right_contour1",
                                     @"mouth_upper_lip_right_contour2",@"mouth_upper_lip_right_contour3",@"mouth_upper_lip_top",@"nose_contour_left1",@"nose_contour_left2",@"nose_contour_left3",
                                     @"nose_contour_lower_middle",@"nose_contour_right1",@"nose_contour_right2",@"nose_contour_right3",@"nose_left",@"nose_right",@"nose_tip",@"right_eye_bottom",
                                     @"right_eye_center",@"right_eye_left_corner",@"right_eye_lower_left_quarter",@"right_eye_lower_right_quarter",@"right_eye_pupil",@"right_eye_right_corner",
                                     @"right_eye_top",@"right_eye_upper_left_quarter",@"right_eye_upper_right_quarter",@"right_eyebrow_left_corner",@"right_eyebrow_lower_left_quarter",
                                     @"right_eyebrow_lower_middle",@"right_eyebrow_lower_right_quarter",@"right_eyebrow_right_corner",@"right_eyebrow_upper_left_quarter",
                                     @"right_eyebrow_upper_middle",@"right_eyebrow_upper_right_quarter", nil];
            slider.hidden = NO;
//            NSString *gender = [detectResult content][@"face"][0][@"attribute"][@"gender"][@"value"];
            NSString *currentFaceId = [detectResult content][@"face"][0][@"face_id"];
            FaceppResult *landmarkResult = [[FaceppAPI detection] landmarkWithFaceId:currentFaceId andType:FaceppLandmark83P];
            NSDictionary *landmark = [landmarkResult content][@"result"][0][@"landmark"];
            double sx[83], sy[83];
            for (int i = 0; i < 83; i++) {
                sx[i] = [[landmark objectForKey:landmarkKeys[i]][@"x"] doubleValue];
                sy[i] = [[landmark objectForKey:landmarkKeys[i]][@"y"] doubleValue];
            }
            inputpoint.clear();
            for (int i = 0; i<83; i++)
            {
                inputpoint.push_back(Point2d(sx[i], sy[i]));
            }
            originView.image = image;
            I1 = [self cvMatFromUIImage:image];
            initialize(I1,inputpoint);
            cv::Mat I2 = smile(I1, 1.3);
            [imageView setImage:[self UIImageFromCVMat:I2]];
            slider.value = 1;
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"出错啦"
                              message:@"请检查网络设置"
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    retake.hidden = NO;
    imageView.hidden = NO;
    compare.hidden = NO;
}
- (void)sliderValueChanged {
    cv::Mat I2 = smile(I1, slider.value * 1.3);
    [imageView setImage:[self UIImageFromCVMat:I2]];
}
-(void)compareButtonUp {
    originView.hidden = YES;
}
-(void)compareButtonDown {
    originView.hidden = NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#ifdef __cplusplus
using namespace cv;
using namespace std;
#define max_count 250
#define qlevel 0.05
#define minDist 0
vector<Point2f> smilevector;
vector<Point2f> standardface;
Mat hdx, hdy, mapx, mapy;
inline double disBetweenPoint(Point2d p1, Point2d p2)
{
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

inline double RadialBasisFunction(double r)
{
    if (r <= 1)
    {
        return 0;
    }
    else
    {
        return r*r*log(r);
    }
}

inline double GetDisplacement(const Mat &w, const vector<Point2f> &pointDst, double x, double y)
{
    float *p = (float *)w.data;
    double ans = 0;
    for (int i = 0; i<pointDst.size(); i++)
    {
        ans+=*p * RadialBasisFunction(disBetweenPoint(pointDst[i], Point2f(x,y)));
        p++;
    }
    ans+= *p;
    p++;
    ans += *p * x;
    p++;
    ans += *p * y;
    return ans;
}
vector<Point2f> getContour(vector<Point2f> &landmarks)
{
    vector<Point2f> ans;
    for (int i = 1; i<=9; i++)
        ans.push_back(landmarks[i]);
    for (int i = 18; i>=10; i--)
        ans.push_back(landmarks[i]);
    ans.push_back(landmarks[79]);
    ans.push_back(landmarks[82]);
    ans.push_back(landmarks[81]);
    ans.push_back(landmarks[35]);
    ans.push_back(landmarks[34]);
    ans.push_back(landmarks[29]);
    return ans;
}
void Line_DDA(Mat isvalid, Point2f p1, Point2f p2)
{
    int steps = abs(p2.x - p1.x) > abs(p2.y - p1.y) ? (int)ceil(abs(p2.x - p1.x)) : (int)ceil(abs(p2.y - p1.y));
    if (steps == 0)
        return;
    float cx = (p2.x - p1.x) / steps, cy = (p2.y - p1.y) / steps;
    float x = p1.x, y = p1.y;
    for (int i = 0; i < steps; i++)
    {
        isvalid.at<uchar>((int)round(y), (int)round(x)) = 1;
        x += cx;
        y += cy;
    }
    isvalid.at<uchar>((int)round(y), (int)round(x)) = 1;
}
Mat getFaceBitmap(cv::Size imgsize, vector<Point2f> &points, double scale = 1)
{
    vector<Point2f> landmarks;
    for (int i = 0; i<points.size(); i++)
        landmarks.push_back(Point2f(points[i].x/scale, points[i].y/scale));
    Mat isvalid(imgsize, CV_8U, Scalar(0));
    vector<Point2f> contour = getContour(landmarks);
    for (int i = 0; i<contour.size()-1; i++)
        Line_DDA(isvalid, contour[i], contour[i+1]);
    Line_DDA(isvalid, contour[contour.size()-1], contour[0]);
    floodFill(isvalid, landmarks[56], 1);
    return isvalid;
}
void ThinPlateSpline(const vector<Point2f> &pointsSrc,const vector<Point2f> &pointsDst,
                     Mat &wx, Mat &wy, double lamda = 0.01)
//reference:http://elonen.iki.fi/code/tpsdemo/
{
    // first formulize into system of linear equations: L*x = b
    int p = pointsDst.size();
    Mat L(pointsSrc.size()+3, pointsSrc.size()+3, CV_32F);
    double alpha = 0;
    for (int i = 0; i < p; i++)
    {
        for (int j = 0; j < p; j++)
        {
            alpha += disBetweenPoint(pointsDst[i], pointsDst[j]);
        }
        for (int j = 0; j < i; j++)
        {
            L.at<float>(i, j) = RadialBasisFunction(disBetweenPoint(pointsDst[i], pointsDst[j]));
        }
    }
    alpha /= p*p;
    double diagK = alpha*alpha*lamda;
    for (int i = 0; i < p ; i++)
    {
        L.at<float>(i, i) = diagK;
    }
    for (int i = p; i < p + 3; i++)
    {
        for (int j = p; j <= i; j++)
        {
            L.at<float>(i, j) = 0;
        }
    }
    for (int j = 0; j < p; j++)
    {
        L.at<float>(p, j) = 1;
        L.at<float>(p + 1, j) = pointsDst[j].x;
        L.at<float>(p + 2, j) = pointsDst[j].y;
    }
    //upper diagonal element, symmetric matrix
    for (int i = 0; i < p + 3; i++)
    {
        for (int j = i + 1; j < p + 3; j++)
        {
            L.at<float>(i, j) = L.at<float>(j, i);
        }
    }
    Mat bx(p+3,1,CV_32F);
    Mat by(p+3,1,CV_32F);
    for (int i = 0; i < p; i++)
    {
        bx.at<float>(i,0) = pointsSrc[i].x - pointsDst[i].x;
        by.at<float>(i,0) = pointsSrc[i].y - pointsDst[i].y;
    }
    for (int i = p; i < p + 3; i++)
    {
        bx.at<float>(i,0) = 0;
        by.at<float>(i,0) = 0;
    }
    
    Mat d, u, vt;
    SVD::compute(L, d, u, vt);
    Mat d_inv(d.rows,d.rows,CV_32F,Scalar(0));
    
    for (int i = 0; i < p + 3; i++)
    {
        //for ill-conditioned matrix, remove the trival eigenvalues
        if (d.at<float>(i,0) < 1)
        {
            continue;
        }
        d_inv.at<float>(i, i) = 1 / d.at<float>(i,0);
    }
    
    //since L is symmetric here U = V;
    wx = u*(d_inv*(vt*bx));
    wy = u*(d_inv*(vt*by));
    
    
}

Mat smile(Mat image,  double lamda)
{
    
    
    Mat warped;
    double c = lamda/1.3;
    remap(image, warped, mapx+c*hdx, mapy+c*hdy, INTER_NEAREST, BORDER_REPLICATE);
    return warped;
}
void initialize(Mat image, vector<Point2f> inputpoint)
{
    for (int i = 0; i<inputpoint.size(); i++)
    {
        inputpoint[i].x *= 1.0*image.cols/100;
        inputpoint[i].y *= 1.0*image.rows/100;
    }
    NSString *paths = [[NSBundle mainBundle] pathForResource:@"smileface" ofType:@"txt"];
    const char *path = [paths UTF8String];
    freopen(path, "r", stdin);
    double dx[83] ,dy[83], meanx[83], meany[83];
    for (int i = 0; i<83; i++)
        scanf("%lf", dx+i);
    for (int i = 0; i<83; i++)
        scanf("%lf", dy+i);
    for (int i = 0; i<83; i++)
        scanf("%lf", meanx+i);
    for (int i = 0; i<83; i++)
        scanf("%lf", meany+i);
    smilevector.clear();
    standardface.clear();
    for (int i = 0; i<83; i++)
    {
        smilevector.push_back(Point2f(dx[i], dy[i]));
        standardface.push_back(Point2f(meanx[i], meany[i]));
    }
    
    fclose(stdin);
    
    vector<Point2f> outputpoint, meanpoint;
    Mat tform = estimateRigidTransform(inputpoint, standardface, false);
    Mat tform_inv = estimateRigidTransform(standardface, inputpoint,false);
    double a = tform_inv.at<double>(0, 0), b = tform_inv.at<double>(0,1);
    float scale =  sqrt(a*a + b*b);
    transform(inputpoint, meanpoint, tform);
    
    
    for (int i = 0; i<meanpoint.size(); i++)
        meanpoint[i] = meanpoint[i] + 1.3*smilevector[i];
    
    transform(meanpoint, outputpoint, tform_inv);
    //    Mat warped2 = imgwarp(image, inputpoint, outputpoint);
    //    imshow("tps", warped2);
    
    int standard_width = 200, standard_height = 250;
    
    float minx = standard_width,maxx = 0, miny = standard_height ,maxy = 0;
    for (int i = 0; i<83; i++)
    {
        minx = min(minx, outputpoint[i].x);
        maxx = max(maxx, outputpoint[i].x);
        miny = min(miny, outputpoint[i].y);
        maxy = max(maxy, outputpoint[i].y);
    }
    
    
    Mat wx, wy;
    //    Point2f lt(0,0), rt(image.cols, 0), lb(0, image.rows), rb(image.cols, image.rows);
    //    inputpoint.push_back(lt);
    //    inputpoint.push_back(rt);
    //    inputpoint.push_back(lb);
    //    inputpoint.push_back(rb);
    //    outputpoint.push_back(lt);
    //    outputpoint.push_back(rt);
    //    outputpoint.push_back(lb);
    //    outputpoint.push_back(rb);
    ThinPlateSpline(inputpoint, outputpoint, wx, wy);
    
    
    scale *= 2;
    cv::Size dsize(image.cols/scale,image.rows/scale);
    Mat facebitmap = getFaceBitmap(dsize, outputpoint, scale);
    Mat ldx(dsize, CV_32F, Scalar(0)), ldy(dsize, CV_32F, Scalar(0));
    for (int i = miny/scale; i<maxy/scale; i++)
        for (int j = minx/scale; j<maxx/scale; j++)
            if (facebitmap.at<uchar>(i,j) == 1)
            {
                ldx.at<float>(i,j) = GetDisplacement(wx, outputpoint, j*scale, i*scale);
                ldy.at<float>(i,j) = GetDisplacement(wy, outputpoint, j*scale, i*scale);
            }
    
    
    resize(ldx, hdx, image.size(), 0,0, INTER_LINEAR);
    resize(ldy, hdy, image.size(), 0,0, INTER_LINEAR);
    
    mapx = Mat(image.size(),CV_32F);
    mapy = Mat(image.size(),CV_32F);
    
    float *px = (float *)mapx.data, *py = (float *)mapy.data;
    for (int i = 0; i<image.rows; i++)
        for (int j = 0; j<image.cols; j++)
        {
            *px += j;
            px++;
            *py += i;
            py++;
        }
}
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
//    cv::Mat greyMat;
//    cv::cvtColor(cvMat,greyMat,CV_BGR2GRAY);
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}
#endif
@end
