import streamlit as st
import requests

st.set_page_config(page_title="Codebase Genius", page_icon="🚀")

st.title("🚀 Codebase Genius")
st.subheader("AI-Powered Code Documentation")

repo_url = st.text_input("GitHub Repository URL:", placeholder="https://github.com/username/repo")

if st.button("Generate Documentation", type="primary"):
    if repo_url:
        with st.spinner("Analyzing repository..."):
            try:
                response = requests.post(
                    "http://localhost:8000/walker/doc_walker",
                    json={"repo_url": repo_url},
                    timeout=300
                )
                
                if response.status_code == 200:
                    result = response.json()
                    st.success("Documentation generated!")
                    st.json(result)
                    
                    if result.get("path"):
                        st.info(f"Saved to: {result['path']}")
                else:
                    st.error(f"Error: {response.status_code}")
            except Exception as e:
                st.error(f"Error: {e}")
    else:
        st.error("Enter a repo URL!")