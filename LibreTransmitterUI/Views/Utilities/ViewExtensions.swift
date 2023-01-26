//
//  ViewExtensions.swift
//  LibreTransmitterUI
//
//  Created by Bjørn Inge Berg on 03/07/2021.
//  Copyright © 2021 Mark Wilson. All rights reserved.
//

import SwiftUI
import LocalAuthentication

#if canImport(UIKit)
extension View {
    func hideKeyboardPreIos16() {
        if #unavailable(iOS 16.0) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
#endif

extension View {
    func getLeadingImage() -> some View{
        Image(uiImage: UIImage(named: "libresensor200", in: Bundle.current, compatibleWith: nil)!)
        .resizable()
        .aspectRatio(contentMode: ContentMode.fit)
        .frame(height: 100)
        .padding(.horizontal)
    }
    
    
    func authenticate(success authSuccess: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        print("dabear:: authenticate")
        // check whether authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {  success, authenticationError  in
                print("dabear:: context.evaluatePolicy: \(success)")
                authSuccess(success)
            }
        } else {
            // no auth, automatically allow
            print("dabear:: could not evaulate ownerpolicy")
            authSuccess(true)
        }
    }
}
