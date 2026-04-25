import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.accentColor)
                        Text("Flippers")
                            .font(.largeTitle.bold())
                        Text("일본어 플래시카드")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    if let message = vm.configurationMessage {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(message)
                                .font(.footnote)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // MARK: - Mode Toggle
                    Picker("모드", selection: $vm.isSignUpMode) {
                        Text("로그인").tag(false)
                        Text("회원가입").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!vm.isAuthenticationAvailable)
                    .padding(.horizontal)
                    .onChange(of: vm.isSignUpMode) { _, _ in
                        vm.errorMessage = nil
                    }

                    // MARK: - Email Form
                    VStack(spacing: 12) {
                        TextField("이메일", text: $vm.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .disabled(!vm.isAuthenticationAvailable)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        SecureField("비밀번호", text: $vm.password)
                            .textContentType(vm.isSignUpMode ? .newPassword : .password)
                            .disabled(!vm.isAuthenticationAvailable)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)

                    // MARK: - Error
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Submit Button
                    Button {
                        Task { await viewModel.submitEmail() }
                    } label: {
                        Group {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(vm.isSignUpMode ? "회원가입" : "로그인")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.email.isEmpty || vm.password.isEmpty || vm.isLoading || !vm.isAuthenticationAvailable)
                    .padding(.horizontal)

                    // MARK: - Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color(.separator))
                        Text("또는")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color(.separator))
                    }
                    .padding(.horizontal)

                    // MARK: - Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        viewModel.prepareAppleSignInRequest(request)
                    } onCompletion: { result in
                        Task { await viewModel.handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .disabled(!vm.isAuthenticationAvailable || vm.isLoading)
                    .frame(height: 50)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthViewModel())
}
